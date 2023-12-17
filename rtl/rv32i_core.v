/* The rv32i_core module represents the top module for an RV32I RISC-V processor 
core. The module is structured around a 5-stage pipeline architecture, which 
includes Fetch, Decode, Execute, Memory Access, and Writeback stages. The RV32I 
core is designed to interface with separate instruction and data memories, and 
supports external, software, and timer interrupts. The module contains several 
sub-modules that carry out various functions within the processor:
 - rv32i_forwarding: This sub-module is responsible for handling operand
    forwarding. It ensures that the correct operand values are used in the ALU 
    stage, even when they have not yet been written back to the register file.
    Operand forwarding helps to reduce pipeline stalls caused by data 
    dependencies.
 - rv32i_basereg: This sub-module serves as a controller for the 32 integer 
    base registers. It manages reading from and writing to the register file, 
    with read operations occurring during the Decode stage and write operations 
    during the Writeback stage.
 - rv32i_fetch: This sub-module is responsible for fetching instructions from
    the instruction memory. It generates the instruction address, retrieves 
    the instruction, and controls the program counter (PC). It also manages 
    the pipeline stall and flush signals for the Fetch stage.
 - rv32i_decoder: This sub-module takes care of decoding the fetched 32-bit
    instruction. It extracts various fields from the instruction, such as opcode,
    function type, immediate value, and register addresses. The sub-module also 
    detects exceptions, manages pipeline stall and flush signals for the Decode 
    stage, and provides a clock enable signal for the next stage.
 - rv32i_alu: This sub-module is the Arithmetic Logic Unit (ALU) of the core.
    It performs arithmetic and logical operations based on the opcode and 
    function type provided by the decoder. It also controls the program counter
    for branches and jumps, manages register write enable signals, and handles 
    pipeline stall and flush signals for the Execute stage.
 - rv32i_memoryaccess: This sub-module controls data memory access for load and 
    store operations. It computes the memory address based on the ALU output 
    and provides the appropriate signals for reading from or writing to the data
    memory. The sub-module also manages pipeline stall and flush signals for 
    the Memory Access stage.
 - rv32i_writeback: This sub-module is responsible for writing the results of ALU 
    and load operations back to the register file. It also manages the program 
    counter for returning from traps and provides clock enable signals for the 
    Writeback stage.
 - rv32i_csr: This sub-module manages the Control and Status Registers (CSRs) in 
    the core. It handles traps and exceptions, updates CSR values, and controls 
    the program counter for trap handling.
*/

`timescale 1ns / 1ps
`default_nettype none
`include "rv32i_header.vh"

module rv32i_core #(parameter PC_RESET = 32'h00_00_00_00, TRAP_ADDRESS = 0, ZICSR_EXTENSION = 1) ( 
    input wire i_clk, i_rst_n,
    //Instruction Memory Interface (32 bit rom)
    input wire[31:0] i_inst, //32-bit instruction
    output wire[31:0] o_iaddr, //address of instruction 
    output wire o_stb_inst, //request for read access to instruction memory
    input wire i_ack_inst, //ack (high if new instruction is ready)
    //Data Memory Interface (32 bit ram)
    output wire o_wb_cyc_data, //bus cycle active (1 = normal operation, 0 = all ongoing transaction are to be cancelled)
    output wire o_wb_stb_data, //request for read/write access to data memory
    output wire o_wb_we_data, //write-enable (1 = write, 0 = read)
    output wire[31:0] o_wb_addr_data, //address of data memory for store/load
    output wire[31:0] o_wb_data_data, //data to be stored to memory
    output wire[3:0] o_wb_sel_data, //byte strobe for write (1 = write the byte) {byte3,byte2,byte1,byte0}
    input wire i_wb_ack_data, //ack by data memory (high when read data is ready or when write data is already written)
    input wire i_wb_stall_data, //stall by data memory 
    input wire[31:0] i_wb_data_data, //data retrieve from memory
    //Interrupts
    input wire i_external_interrupt, //interrupt from external source
    input wire i_software_interrupt, //interrupt from software (inter-processor interrupt)
    input wire i_timer_interrupt //interrupt from timer
);
    
   
    //wires for basereg
    wire[31:0] rs1_orig,rs2_orig;   
    wire[31:0] rs1,rs2;  
    wire ce_read;

    //wires for rv32i_fetch
     wire[31:0] fetch_pc;
     wire[31:0] fetch_inst;

    //wires for rv32i_decoder
    wire[`ALU_WIDTH-1:0] decoder_alu;
    wire[`OPCODE_WIDTH-1:0] decoder_opcode;
    wire[31:0] decoder_pc;
    wire[4:0] decoder_rs1_addr, decoder_rs2_addr;
    wire[4:0] decoder_rs1_addr_q, decoder_rs2_addr_q;
    wire[4:0] decoder_rd_addr; 
    wire[31:0] decoder_imm; 
    wire[2:0] decoder_funct3;
    wire[`EXCEPTION_WIDTH-1:0] decoder_exception;
    wire decoder_ce;
    wire decoder_flush;

    //wires for rv32i_alu
    wire[`OPCODE_WIDTH-1:0] alu_opcode;
    wire[4:0] alu_rs1_addr;
    wire[31:0] alu_rs1;
    wire[31:0] alu_rs2;
    wire[11:0] alu_imm;
    wire[2:0] alu_funct3;
    wire[31:0] alu_y;
    wire[31:0] alu_pc;
    wire[31:0] alu_next_pc;
    wire alu_change_pc;
    wire alu_wr_rd;
    wire[4:0] alu_rd_addr;
    wire[31:0] alu_rd;
    wire alu_rd_valid;
    wire[`EXCEPTION_WIDTH-1:0] alu_exception;
    wire alu_ce;
    wire alu_flush;
    wire alu_force_stall;

    //wires for rv32i_memoryaccess
    wire[`OPCODE_WIDTH-1:0] memoryaccess_opcode;
    wire[2:0] memoryaccess_funct3;
    wire[31:0] memoryaccess_pc;
    wire memoryaccess_wr_rd;
    wire[4:0] memoryaccess_rd_addr;
    wire[31:0] memoryaccess_rd;
    wire[31:0] memoryaccess_data_load;
    wire memoryaccess_wr_mem;
    wire memoryaccess_ce;
    wire memoryaccess_flush;
    wire o_stall_from_alu;
    //wires for rv32i_writeback
    wire writeback_wr_rd; 
    wire[4:0] writeback_rd_addr; 
    wire[31:0] writeback_rd;
    wire[31:0] writeback_next_pc;
    wire writeback_change_pc;
    wire writeback_ce;
    wire writeback_flush;

    //wires for rv32i_csr
    wire[31:0] csr_out; //CSR value to be stored to basereg
    wire[31:0] csr_return_address; //mepc CSR
    wire[31:0] csr_trap_address; //mtvec CSR
    wire csr_go_to_trap; //high before going to trap (if exception/interrupt detected)
    wire csr_return_from_trap; //high before returning from trap (via mret)
    
    wire stall_decoder,
         stall_alu,
         stall_memoryaccess,
         stall_writeback; //control stall of each pipeline stages
    assign ce_read = decoder_ce && !stall_decoder; //reads basereg only decoder is not stalled 

    //module instantiations
    rv32i_forwarding operand_forwarding ( //logic for operand forwarding
        .i_rs1_orig(rs1_orig), //current rs1 value saved in basereg
        .i_rs2_orig(rs2_orig), //current rs2 value saved in basereg
        .i_decoder_rs1_addr_q(decoder_rs1_addr_q), //address of operand rs1 used in ALU stage
        .i_decoder_rs2_addr_q(decoder_rs2_addr_q), //address of operand rs2 used in ALU stage
        .o_alu_force_stall(alu_force_stall), //high to force ALU stage to stall
        .o_rs1(rs1), //rs1 value with Operand Forwarding
        .o_rs2(rs2), //rs2 value with Operand Forwarding
        // Stage 4 [MEMORYACCESS]
        .i_alu_rd_addr(alu_rd_addr), //destination register address
        .i_alu_wr_rd(alu_wr_rd), //high if rd_addr will be written
        .i_alu_rd_valid(alu_rd_valid), //high if rd is already valid at this stage (not LOAD nor CSR instruction)
        .i_alu_rd(alu_rd), //rd value in stage 4
        .i_memoryaccess_ce(memoryaccess_ce), //high if stage 4 is enabled
        // Stage 5 [WRITEBACK]
        .i_memoryaccess_rd_addr(memoryaccess_rd_addr), //destination register address
        .i_memoryaccess_wr_rd(memoryaccess_wr_rd), //high if rd_addr will be written
        .i_writeback_rd(writeback_rd), //rd value in stage 5
        .i_writeback_ce(writeback_ce) //high if stage 4 is enabled
    );

    rv32i_basereg m0( //regfile controller for the 32 integer base registers
        .i_clk(i_clk),
        .i_ce_read(ce_read), //clock enable for reading from basereg [STAGE 2]
        .i_rs1_addr(decoder_rs1_addr), //source register 1 address
        .i_rs2_addr(decoder_rs2_addr), //source register 2 address
        .i_rd_addr(writeback_rd_addr), //destination register address
        .i_rd(writeback_rd), //data to be written to destination register
        .i_wr(writeback_wr_rd), //write enable
        .o_rs1(rs1_orig), //source register 1 value
        .o_rs2(rs2_orig) //source register 2 value
    );
    
    rv32i_fetch #(.PC_RESET(PC_RESET)) m1( // logic for fetching instruction [FETCH STAGE , STAGE 1]
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .o_iaddr(o_iaddr), //Instruction address
        .o_pc(fetch_pc), //PC value of o_inst
        .i_inst(i_inst), // retrieved instruction from Memory
        .o_inst(fetch_inst), // instruction
        .o_stb_inst(o_stb_inst), // request for instruction
        .i_ack_inst(i_ack_inst), //ack (high if new instruction is ready)
        // PC Control
        .i_writeback_change_pc(writeback_change_pc), //high when PC needs to change when going to trap or returning from trap
        .i_writeback_next_pc(writeback_next_pc), //next PC due to trap
        .i_alu_change_pc(alu_change_pc), //high when PC needs to change for taken branches and jumps
        .i_alu_next_pc(alu_next_pc), //next PC due to branch or jump
        /// Pipeline Control ///
        .o_ce(decoder_ce), // output clk enable for pipeline stalling of next stage
        .i_stall((stall_decoder || stall_alu || stall_memoryaccess || stall_writeback)), //informs this stage to stall
        .i_flush(decoder_flush) //flush this stage
    ); 
  
    rv32i_decoder m2( //logic for the decoding of the 32 bit instruction [DECODE STAGE , STAGE 2]
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_inst(fetch_inst), //32 bit instruction
        .i_pc(fetch_pc), //PC value from fetch stage
        .o_pc(decoder_pc), //PC value
        .o_rs1_addr(decoder_rs1_addr),// address for register source 1
        .o_rs1_addr_q(decoder_rs1_addr_q), // registered address for register source 1
        .o_rs2_addr(decoder_rs2_addr), // address for register source 2
        .o_rs2_addr_q(decoder_rs2_addr_q), // registered address for register source 2
        .o_rd_addr(decoder_rd_addr), // address for destination register
        .o_imm(decoder_imm), // extended value for immediate
        .o_funct3(decoder_funct3), // function type
        .o_alu(decoder_alu), //alu operation type
        .o_opcode(decoder_opcode), //opcode type
        .o_exception(decoder_exception), //exceptions: illegal inst, ecall, ebreak, mret
         /// Pipeline Control ///
        .i_ce(decoder_ce), // input clk enable for pipeline stalling of this stage
        .o_ce(alu_ce), // output clk enable for pipeline stalling of next stage
        .i_stall((stall_alu || stall_memoryaccess || stall_writeback)), //informs this stage to stall
        .o_stall(stall_decoder), //informs pipeline to stall
        .i_flush(alu_flush), //flush this stage
        .o_flush(decoder_flush) //flushes previous stages
    );

    rv32i_alu m3( //ALU combinational logic [EXECUTE STAGE , STAGE 3]
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_alu(decoder_alu), //alu operation type
        .i_rs1_addr(decoder_rs1_addr_q), //address for register source 1
        .o_rs1_addr(alu_rs1_addr), //address for register source 1
        .i_rs1(rs1), //Source register 1 value
        .o_rs1(alu_rs1), //Source register 1 value
        .i_rs2(rs2), //Source Register 2 value
        .o_rs2(alu_rs2), //Source Register 2 value
        .i_imm(decoder_imm), //Immediate value from previous stage
        .o_imm(alu_imm), //Immediate value
        .i_funct3(decoder_funct3), //function type from decoder stage
        .o_funct3(alu_funct3), //function type
        .i_opcode(decoder_opcode), //opcode type from previous stage
        .o_opcode(alu_opcode), //opcode type
        .i_exception(decoder_exception), //exception from decoder stage
        .o_exception(alu_exception), //exception: illegal inst,ecall,ebreak,mret
        .o_y(alu_y), //result of arithmetic operation
        // PC Control
        .i_pc(decoder_pc), //pc from decoder stage
        .o_pc(alu_pc), // current pc 
        .o_next_pc(alu_next_pc), //next pc 
        .o_change_pc(alu_change_pc), //change pc if high
        // Basereg Control
        .o_wr_rd(alu_wr_rd), //write rd to basereg if enabled
        .i_rd_addr(decoder_rd_addr), //address for destination register (from previous stage)
        .o_rd_addr(alu_rd_addr), //address for destination register
        .o_rd(alu_rd), //value to be written back to destination register
        .o_rd_valid(alu_rd_valid), //high if o_rd is valid (not load nor csr instruction)
         /// Pipeline Control ///
        .o_stall_from_alu(o_stall_from_alu), //prepare to stall next stage(memory-access stage) for load/store instruction
        .i_ce(alu_ce), // input clk enable for pipeline stalling of this stage
        .o_ce(memoryaccess_ce), // output clk enable for pipeline stalling of next stage
        .i_stall((stall_memoryaccess || stall_writeback)), //informs this stage to stall
        .i_force_stall(alu_force_stall), //force this stage to stall
        .o_stall(stall_alu), //informs pipeline to stall
        .i_flush(memoryaccess_flush), //flush this stage
        .o_flush(alu_flush) //flushes previous stages
    );
    
    rv32i_memoryaccess m4( //logic controller for data memory access (load/store) [MEMORY STAGE , STAGE 4]
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_rs2(alu_rs2), //data to be stored to memory is always rs2
        .i_y(alu_y), //y value from ALU (address of data to memory be stored or loaded)
        .i_funct3(alu_funct3), //funct3 from previous stage
        .o_funct3(memoryaccess_funct3), //funct3 (byte,halfword,word)
        .i_opcode(alu_opcode), //opcode type from previous stage
        .o_opcode(memoryaccess_opcode), //opcode type
        .i_pc(alu_pc), //PC from previous stage
        .o_pc(memoryaccess_pc), //PC value
        // Basereg Control
        .i_wr_rd(alu_wr_rd), //write rd to base reg is enabled (from memoryaccess stage)
        .o_wr_rd(memoryaccess_wr_rd), //write rd to the base reg if enabled
        .i_rd_addr(alu_rd_addr), //address for destination register (from previous stage)
        .o_rd_addr(memoryaccess_rd_addr), //address for destination register
        .i_rd(alu_rd), //value to be written back to destination reg
        .o_rd(memoryaccess_rd), //value to be written back to destination register
        // Data Memory Control
        .o_wb_cyc_data(o_wb_cyc_data), //bus cycle active (1 = normal operation, 0 = all ongoing transaction are to be cancelled)
        .o_wb_stb_data(o_wb_stb_data), //request for read/write access to data memory
        .o_wb_we_data(o_wb_we_data),  //write-enable (1 = write, 0 = read)
        .o_wb_addr_data(o_wb_addr_data), //data memory address
        .o_wb_data_data(o_wb_data_data), //data to be stored to memory (mask-aligned)
        .o_wb_sel_data(o_wb_sel_data), //byte strobe for write (1 = write the byte) {byte3,byte2,byte1,byte0}
        .i_wb_ack_data(i_wb_ack_data), //ack by data memory (high when read data is ready or when write data is already written
        .i_wb_stall_data(i_wb_stall_data), //stall by data memory (1 = data memory is busy)
        .i_wb_data_data(i_wb_data_data), //data retrieve from data memory 
        .o_data_load(memoryaccess_data_load), //data to be loaded to base reg (z-or-s extended) 
         /// Pipeline Control ///   
        .i_stall_from_alu(o_stall_from_alu), //stalls this stage when incoming instruction is a load/store
        .i_ce(memoryaccess_ce), // input clk enable for pipeline stalling of this stage
        .o_ce(writeback_ce), // output clk enable for pipeline stalling of next stage
        .i_stall(stall_writeback), //informs this stage to stall
        .o_stall(stall_memoryaccess), //informs pipeline to stall
        .i_flush(writeback_flush), //flush this stage
        .o_flush(memoryaccess_flush) //flushes previous stages
    );
    
    rv32i_writeback m5( //logic controller for the next PC and rd value [WRITEBACK STAGE , STAGE 5]
        .i_funct3(memoryaccess_funct3), //function type
        .i_data_load(memoryaccess_data_load), //data to be loaded to base reg (from previous stage)
        .i_csr_out(csr_out), //CSR value to be loaded to basereg
        .i_opcode_load(memoryaccess_opcode[`LOAD]),
        .i_opcode_system(memoryaccess_opcode[`SYSTEM]), 
        // Basereg Control
        .i_wr_rd(memoryaccess_wr_rd), //write rd to base reg is enabled (from memoryaccess stage)
        .o_wr_rd(writeback_wr_rd), //write rd to the base reg if enabled
        .i_rd_addr(memoryaccess_rd_addr), //address for destination register (from previous stage)
        .o_rd_addr(writeback_rd_addr), //address for destination register
        .i_rd(memoryaccess_rd), //value to be written back to destination reg
        .o_rd(writeback_rd), //value to be written back to destination register
        // PC Control
        .i_pc(memoryaccess_pc), //pc value
        .o_next_pc(writeback_next_pc), //new PC value
        .o_change_pc(writeback_change_pc), //high if PC needs to jump
        // Trap-Handler
        .i_go_to_trap(csr_go_to_trap), //high before going to trap (if exception/interrupt detected)
        .i_return_from_trap(csr_return_from_trap), //high before returning from trap (via mret)
        .i_return_address(csr_return_address), //mepc CSR
        .i_trap_address(csr_trap_address), //mtvec CSR
        /// Pipeline Control ///
        .i_ce(writeback_ce), // input clk enable for pipeline stalling of this stage
        .o_stall(stall_writeback), //informs pipeline to stall
        .o_flush(writeback_flush) //flushes previous stages 
    );
    
    // removable extensions
    if(ZICSR_EXTENSION == 1) begin: zicsr
        rv32i_csr #(.TRAP_ADDRESS(TRAP_ADDRESS)) m6( // control logic for Control and Status Registers (CSR) [STAGE 4]
            .i_clk(i_clk),
            .i_rst_n(i_rst_n),
            // Interrupts
            .i_external_interrupt(i_external_interrupt), //interrupt from external source
            .i_software_interrupt(i_software_interrupt), //interrupt from software (inter-processor interrupt)
            .i_timer_interrupt(i_timer_interrupt), //interrupt from timer
            /// Exceptions ///
            .i_is_inst_illegal(alu_exception[`ILLEGAL]), //illegal instruction
            .i_is_ecall(alu_exception[`ECALL]), //ecall instruction
            .i_is_ebreak(alu_exception[`EBREAK]), //ebreak instruction
            .i_is_mret(alu_exception[`MRET]), //mret (return from trap) instruction
            /// Load/Store Misaligned Exception///
            .i_opcode(alu_opcode), //opcode type from alu stage
            .i_y(alu_y), //y value from ALU (address used in load/store/jump/branch)
            /// CSR instruction ///
            .i_funct3(alu_funct3), // CSR instruction operation
            .i_csr_index(alu_imm), //immediate value decoded by decoder
            .i_imm({27'b0,alu_rs1_addr}), //unsigned immediate for immediate type of CSR instruction (new value to be stored to CSR)
            .i_rs1(alu_rs1), //Source register 1 value (new value to be stored to CSR)
            .o_csr_out(csr_out), //CSR value to be loaded to basereg
            // Trap-Handler 
            .i_pc(alu_pc), //Program Counter  (three stages had already been filled [fetch -> decode -> execute ])
            .writeback_change_pc(writeback_change_pc), //high if writeback will issue change_pc (which will override this stage)
            .o_return_address(csr_return_address), //mepc CSR
            .o_trap_address(csr_trap_address), //mtvec CSR
            .o_go_to_trap_q(csr_go_to_trap), //high before going to trap (if exception/interrupt detected)
            .o_return_from_trap_q(csr_return_from_trap), //high before returning from trap (via mret)
            .i_minstret_inc(writeback_ce), //high for one clock cycle at the end of every instruction
            /// Pipeline Control ///
            .i_ce(memoryaccess_ce), // input clk enable for pipeline stalling of this stage
            .i_stall((stall_writeback || stall_memoryaccess)) //informs this stage to stall
        );
    end
    else begin: zicsr
        assign csr_out = 0;
        assign csr_return_address = 0;
        assign csr_trap_address = 0;
        assign csr_go_to_trap = 0;
        assign csr_return_from_trap = 0;
    end
     



   `ifdef FORMAL 
        //f_past_valid logic
        reg f_past_valid = 0;
        always @(posedge i_clk) f_past_valid <= 1;

        // assume initial conditions
        initial begin
            assume(i_rst_n == 0);
        end

        // assumption on inputs(not more than one opcode and alu operation is high)
        wire[4:0] f_alu=decoder_alu[`ADD]+decoder_alu[`SUB]+decoder_alu[`SLT]+decoder_alu[`SLTU]+decoder_alu[`XOR]+decoder_alu[`OR]+decoder_alu[`AND]+decoder_alu[`SLL]+decoder_alu[`SRL]+decoder_alu[`SRA]+decoder_alu[`EQ]+decoder_alu[`NEQ]+decoder_alu[`GE]+decoder_alu[`GEU]+0;
        wire[4:0] f_opcode=decoder_opcode[`RTYPE]+decoder_opcode[`ITYPE]+decoder_opcode[`LOAD]+decoder_opcode[`STORE]+decoder_opcode[`BRANCH]+decoder_opcode[`JAL]+decoder_opcode[`JALR]+decoder_opcode[`LUI]+decoder_opcode[`AUIPC]+decoder_opcode[`SYSTEM]+decoder_opcode[`FENCE]+0;
        always @* begin
            assume(f_alu <= 1);
            assume(f_opcode <= 1);
        end

        wire[4:0] f_outstanding;

   fwb_master #(
		// {{{
		.AW(32),
        .DW(32),
		.F_MAX_STALL(1),
		.F_MAX_ACK_DELAY(1),
		.F_LGDEPTH(4),
		.F_MAX_REQUESTS(0),
		// OPT_BUS_ABORT: If true, the master can drop CYC at any time
		// and must drop CYC following any bus error
		.OPT_BUS_ABORT(1'b1),
		//
		// If true, allow the bus to be kept open when there are no
		// outstanding requests.  This is useful for any master that
		// might execute a read modify write cycle, such as an atomic
		// add.
		.F_OPT_RMW_BUS_OPTION (1),
		//
		//
		// If true, allow the bus to issue multiple discontinuous
		// requests.
		// Unlike F_OPT_RMW_BUS_OPTION, these requests may be issued
		// while other requests are outstanding
		.F_OPT_DISCONTINUOUS(1),
		//
		//
		// If true, insist that there be a minimum of a single clock
		// delay between request and response.  This defaults to off
		// since the wishbone specification specifically doesn't
		// require this.  However, some interfaces do, so we allow it
		// as an option here.
		.F_OPT_MINCLOCK_DELAY(1)
	) fwb_master (
		// {{{
		.i_clk(i_clk), 
        .i_reset(!i_rst_n),
		// The Wishbone bus
		.i_wb_cyc(o_wb_cyc_data), 
        .i_wb_stb(o_wb_stb_data), 
        .i_wb_we(o_wb_we_data),
		.i_wb_addr(o_wb_addr_data),
		.i_wb_data(o_wb_data_data),
		.i_wb_sel(o_wb_sel_data),
		//
		.i_wb_ack(i_wb_ack_data),
		.i_wb_stall(i_wb_stall_data),
		.i_wb_idata(i_wb_data_data),
		.i_wb_err(1'b0),
		// Some convenience output parameters
		.f_nreqs(), 
        .f_nacks(),
		.f_outstanding(f_outstanding)
		// }}}
	);
        always @* begin
            assert(f_outstanding <= 1);
            if(f_outstanding == 1) begin
                assert(!o_wb_stb_data);
            end
        end
  
        /*
        //////////////////////////////////////////////// verify Operand Forwarding ///////////////////////////////////////////////////
        reg[4:0] f_alu_rs2_addr;
        reg[4:0] f_memoryaccess_rs1_addr; 
        reg[4:0] f_memoryaccess_rs2_addr; 
        reg[31:0] f_memoryaccess_rs1;
        reg[31:0] f_memoryaccess_rs2;

        always @(posedge i_clk) begin 
            if(alu_ce && !(stall[`ALU] || stall[`MEMORYACCESS] || stall[`WRITEBACK])) begin //store rs2_addr pipeline register for ALU stage
                f_alu_rs2_addr <= decoder_rs2_addr_q;
            end
            if(memoryaccess_ce && !(stall[`MEMORYACCESS] || stall[`WRITEBACK])) begin //store rs1_addr, rs2_addr, rs1, and rs2  pipeline registers for STAGE 4
                f_memoryaccess_rs1_addr <= alu_rs1_addr;
                f_memoryaccess_rs2_addr <= f_alu_rs2_addr;
                f_memoryaccess_rs1 <= alu_rs1;
                f_memoryaccess_rs2 <= alu_rs2;
            end
        end
        always @(posedge i_clk) begin
            if(writeback_ce) begin //Stage 5 is enabled
                if(f_memoryaccess_rs1_addr != 0) begin
                    assert(f_memoryaccess_rs1 == m0.base_regfile[f_memoryaccess_rs1_addr]); //verify that the rs1 value used from the ALU stage is the MOST updated value
                end
                else assert(f_memoryaccess_rs1 == 0);

                if(f_memoryaccess_rs2_addr != 0) begin
                    assert(f_memoryaccess_rs2 == m0.base_regfile[f_memoryaccess_rs2_addr]); //verify that the rs2 value used from the ALU stage is the MOST updated value
                end
                else assert(f_memoryaccess_rs2 == 0);
            end
        end
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        

        ///////////////////////////////// verify that taken branches, jumps, and traps will update PC ///////////////////////////////////
        always @(posedge i_clk) begin
            // change_pc in stage 5 (due to traps) will force first stage to change PC in next clk cycle and all _ce to be
            // disabled
            if($past(writeback_change_pc) && $past(writeback_ce) && i_rst_n && f_past_valid) begin
                assert(o_iaddr == $past(writeback_next_pc));  
                assert({writeback_ce,memoryaccess_ce,alu_ce,decoder_ce}  == 0);
            end

            // change_pc in stage 3 (due to jumps and branches) will force first stage to change PC in next clock cycle unless
            // stalled by stage 3(due to data dependency) or stage 4(due to load instruction) or be flushed by stage 5(due traps)
            // and all _ce of previous stages of STAGE 3 to be disabled
            else if($past(alu_change_pc) && $past(alu_ce) && !$past(stall_alu) && i_rst_n && f_past_valid) begin
                assert(o_iaddr == $past(alu_next_pc));         
                assert({alu_ce,decoder_ce} == 0);
            end
            
            // verify that if no taken branches,jumps,or traps then PC  will just be added by 4
            if(!$past(writeback_change_pc) && !$past(alu_change_pc) && !$past(stall_decoder || stall_alu || stall_memoryaccess || stall_writeback) 
                 && $past(i_rst_n) && i_rst_n && f_past_valid) begin 
                assert(o_iaddr == $past(o_iaddr)+4);
            end
        end
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        */

        /*
        //////////////////////////////////////// verify valid writes to basereg and data memory /////////////////////////////////////////
        always @(posedge i_clk) begin
            // verify that basereg will be written only if writeback_ce is high
            if(writeback_wr_rd) assert(writeback_ce);
            
            // verify data memory will be written at next clk cycle only if memoryaccess_ce is high and stage 5 does not have to change PC
            if(o_wr_en) assert($past(memoryaccess_ce) && !$past(writeback_change_pc) && !writeback_change_pc);
        end
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

        

        /////////////////////////////////////////////////// verify pipeline stalls /////////////////////////////////////////////////////
        reg cover_tick = 0;
        always @(posedge i_clk) begin
            // verify that when stalled, PC address and _ce will not change
            if(($past(stall)!=0) && i_rst_n && f_past_valid) assert(o_iaddr == $past(o_iaddr));
            if($past(stall[`WRITEBACK]) && i_rst_n && f_past_valid) begin
               assert(writeback_ce == $past(writeback_ce));
               assert(memoryaccess_ce == $past(memoryaccess_ce));
               assert(alu_ce == $past(alu_ce));
               assert(decoder_ce == $past(decoder_ce));
               assert(fetch_ce == $past(fetch_ce));
            end
            if($past(stall[`MEMORYACCESS]) && i_rst_n && f_past_valid) begin
               assert(memoryaccess_ce == $past(memoryaccess_ce));
               assert(alu_ce == $past(alu_ce));
               assert(decoder_ce == $past(decoder_ce));
               assert(fetch_ce == $past(fetch_ce));
            end
            if($past(stall[`ALU]) && i_rst_n && f_past_valid) begin
               assert(alu_ce == $past(alu_ce));
               assert(decoder_ce == $past(decoder_ce));
               assert(fetch_ce == $past(fetch_ce));
            end
            if($past(stall[`DECODER]) && i_rst_n && f_past_valid) begin
               assert(decoder_ce == $past(decoder_ce));
               assert(fetch_ce == $past(fetch_ce));
            end
            if($past(stall[`FETCH]) && i_rst_n && f_past_valid) begin
               assert(fetch_ce == $past(fetch_ce));
            end
            
            //verify that output states of ALU stage will not change if pipeline is stalled
            if($past(alu_ce) && $past(stall[`MEMORYACCESS]) && i_rst_n && f_past_valid) begin
               assert(alu_change_pc == $past(alu_change_pc));
               assert(alu_next_pc == $past(alu_next_pc));
               assert(alu_force_stall == $past(alu_force_stall));
            end

            // verify that if a stage is stalled, then the previous stage should be stalled too
            if(stall[`WRITEBACK]) assert(stall[`MEMORYACCESS]);
            if(stall[`MEMORYACCESS] || (alu_force_stall && !writeback_change_pc)) assert(stall[`ALU]);
            if(stall[`ALU]) assert(stall[`DECODER]);
            if(stall[`DECODER]) assert(stall[`FETCH]);
            if(writeback_change_pc) assert(stall == 0); //pipeline will never be stalled and flushed(by stage 5) at same time
                                                        //No stall can stop flush from stage 5

            // verify that if stage 4 is stalled while stage 5 is not, stage 5 will be disabled at next clk cycle (writeback_ce wil be low) (pipeline bubbling)
            if($past(stall[`MEMORYACCESS]) && !$past(stall[`WRITEBACK]) && $past(i_rst_n) && i_rst_n && f_past_valid) begin
                assert(memoryaccess_ce && !writeback_ce);
            end 
            // verify that if stage 3 is stalled while stage 4 is not, stage 4 will be disabled at next clk cycle (memoryaccess_ce will be low) (pipeline bubbling)
           if($past(alu_force_stall) && !$past(stall[`MEMORYACCESS]) && $past(i_rst_n) && i_rst_n && !$past(writeback_change_pc) && f_past_valid) begin
                assert(alu_ce && !memoryaccess_ce);
           end

        end
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        */

        /*
        //////////////////////////////////////// verify increments of mcycle and minstret CSR ///////////////////////////////////////////
        always @(posedge i_clk) begin
            //verify mcycle will always increment
            if(!$past(zicsr.m6.mcountinhibit_cy) && $past(i_rst_n) && i_rst_n && f_past_valid) begin
                assert(zicsr.m6.mcycle == $past(zicsr.m6.mcycle) + 1);
            end

            //verify minstret will increment for every instruction executed (except for go_to_trap and return_from_trap)
            if($past(!zicsr.m6.mcountinhibit_ir && writeback_ce && !stall[`WRITEBACK] && !csr_go_to_trap && !csr_return_from_trap && i_rst_n) && i_rst_n) begin
              assert(zicsr.m6.minstret == $past(zicsr.m6.minstret) + 1);
            end
        end
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        */


        ////////////////////////////////////////////////////// COVER STATEMENTS /////////////////////////////////////////////////////////
        /*
        always @(posedge i_clk) begin
            // cover 10 instruction executed
            cover(zicsr.m6.minstret == 10);
            // cover write to basereg address 2
            cover(($past(m0.base_regfile[2]) != m0.base_regfile[2]) && f_past_valid); 
            // cover if basereg can change without the wr_rd enabled by writeback stage [FAIL]
            //cover(($past(m0.base_regfile[3]) != m0.base_regfile[3] && f_past_valid) && !$past(writeback_wr_rd));
        end
        */
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    `endif
endmodule
