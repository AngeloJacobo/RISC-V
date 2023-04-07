/* The rv32i_alu module serves as the Arithmetic Logic Unit (ALU) for the RISC-V core 
during the execute stage of the pipeline. The ALU is responsible for executing arithmetic, 
logic, and comparison operations based on the instruction and operands provided. This
module is a crucial part of the RISC-V core, as it processes the instructions and computes 
the results required for program execution. Function includes:
 - Operand Selection: The module first selects the appropriate operands for the ALU operation 
    depending on the opcode. Operand A can be the program counter (PC) or the value of the 
    first source register (rs1), while operand B can be either the second source register 
    (rs2) or an immediate value.
 - ALU Operation: The ALU performs various operations, such as ADD, SUB, SLT, SLTU, XOR, OR, 
    AND, SLL, SRL, SRA, EQ, NEQ, GE, and GEU, depending on the instruction type. The result 
    of the ALU operation is stored in the y_d register.
- Handling Branches and Jumps: The module computes the next PC value based on the instruction 
    type (e.g., branch, jump, or jump-and-link). It also generates the o_change_pc signal to 
    indicate whether the PC needs to jump to a new address.
- Register Writeback: The module computes the value to be written back to the destination 
    register (rd) and sets the appropriate control signals (o_wr_rd and o_rd_valid) based on
    the instruction type. For example, it disables writing to the destination register for 
    branch or store instructions.
 - Stalling and Flushing: The ALU manages stalling and flushing of the pipeline. It generates 
    the o_stall_from_alu signal to stall the memory-access stage for load/store instructions 
    since accessing data memory may take multiple cycles. It also handles pipeline stalls 
    and flushes based on the input signals (i_stall, i_force_stall, and i_flush).
*/


`timescale 1ns / 1ps
`default_nettype none
`include "rv32i_header.vh"

module rv32i_alu(
    input wire i_clk,i_rst_n,
    input wire[`ALU_WIDTH-1:0] i_alu, //alu operation type from previous stage
    input wire[4:0] i_rs1_addr, //address for register source 1
    output reg[4:0] o_rs1_addr, //address for register source 1
    input wire[31:0] i_rs1, //Source register 1 value
    output reg[31:0] o_rs1, //Source register 1 value
    input wire[31:0] i_rs2, //Source register 2 value
    output reg[31:0] o_rs2, //Source register 2 value
    input wire[31:0] i_imm, //Immediate value from previous stage
    output reg[11:0] o_imm, //Immediate value
    input wire[2:0] i_funct3, //function type from previous stage
    output reg[2:0] o_funct3, // function type
    input wire[`OPCODE_WIDTH-1:0] i_opcode, //opcode type from previous stage
    output reg[`OPCODE_WIDTH-1:0] o_opcode, //opcode type 
    input wire[`EXCEPTION_WIDTH-1:0] i_exception, //exception from decoder stage
    output reg[`EXCEPTION_WIDTH-1:0] o_exception, //exception: illegal inst,ecall,ebreak,mret
    output reg[31:0] o_y, //result of arithmetic operation
    // PC Control
    input wire[31:0] i_pc, //Program Counter
    output reg[31:0] o_pc, //pc register in pipeline
    output reg[31:0] o_next_pc, //new pc value
    output reg o_change_pc, //high if PC needs to jump
    // Basereg Control
    output reg o_wr_rd, //write rd to the base reg if enabled
    input wire[4:0] i_rd_addr, //address for destination register (from previous stage)
    output reg[4:0] o_rd_addr, //address for destination register
    output reg[31:0] o_rd, //value to be written back to destination register
    output reg o_rd_valid, //high if o_rd is valid (not load nor csr instruction)
    /// Pipeline Control ///
    output reg o_stall_from_alu, //prepare to stall next stage(memory-access stage) for load/store instruction
    input wire i_ce, // input clk enable for pipeline stalling of this stage
    output reg o_ce, // output clk enable for pipeline stalling of next stage
    input wire i_stall, //informs this stage to stall
    input wire i_force_stall, //force this stage to stall
    output reg o_stall, //informs pipeline to stall
    input wire i_flush, //flush this stage
    output reg o_flush //flush previous stages
);

    wire alu_add = i_alu[`ADD];
    wire alu_sub = i_alu[`SUB];
    wire alu_slt = i_alu[`SLT];
    wire alu_sltu = i_alu[`SLTU];
    wire alu_xor = i_alu[`XOR];
    wire alu_or = i_alu[`OR];
    wire alu_and = i_alu[`AND];
    wire alu_sll = i_alu[`SLL];
    wire alu_srl = i_alu[`SRL];
    wire alu_sra = i_alu[`SRA];
    wire alu_eq = i_alu[`EQ];
    wire alu_neq = i_alu[`NEQ];
    wire alu_ge = i_alu[`GE];
    wire alu_geu = i_alu[`GEU];
    wire opcode_rtype = i_opcode[`RTYPE];
    wire opcode_itype = i_opcode[`ITYPE];
    wire opcode_load = i_opcode[`LOAD];
    wire opcode_store = i_opcode[`STORE];
    wire opcode_branch = i_opcode[`BRANCH];
    wire opcode_jal = i_opcode[`JAL];
    wire opcode_jalr = i_opcode[`JALR];
    wire opcode_lui = i_opcode[`LUI];
    wire opcode_auipc = i_opcode[`AUIPC];
    wire opcode_system = i_opcode[`SYSTEM];
    wire opcode_fence = i_opcode[`FENCE];

    reg[31:0] a; //operand A
    reg[31:0] b; //operand B
    reg[31:0] y_d; //ALU output
    reg[31:0] rd_d; //next value to be written back to destination register
    reg wr_rd_d; //write rd to basereg if enabled
    reg rd_valid_d; //high if rd is valid (not load nor csr instruction)
    reg[31:0] a_pc;
    wire[31:0] sum;
    wire stall_bit = o_stall || i_stall;

    //register the output of i_alu
    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            o_exception <= 0;
            o_ce <= 0;
            o_stall_from_alu <= 0;
        end
        else begin
            if(i_ce && !stall_bit) begin //update register only if this stage is enabled
                o_opcode <= i_opcode;
                o_exception <= i_exception;
                o_y <= y_d; 
                o_rs1_addr <= i_rs1_addr;
                o_rs1 <= i_rs1;
                o_rs2 <= i_rs2;
                o_rd_addr <= i_rd_addr;
                o_imm <= i_imm[11:0];
                o_funct3 <= i_funct3;
                o_rd <= rd_d;
                o_rd_valid <= rd_valid_d;
                o_wr_rd <= wr_rd_d;
                o_stall_from_alu <= i_opcode[`STORE] || i_opcode[`LOAD]; //stall next stage(memory-access stage) when need to store/load 
                o_pc <= i_pc;                                               //since accessing data memory always takes more than 1 cycle
            end
            if(i_flush && !stall_bit) begin //flush this stage so clock-enable of next stage is disabled at next clock cycle
                o_ce <= 0;
            end
            else if(!stall_bit) begin //clock-enable will change only when not stalled
                o_ce <= i_ce;
            end
            else if(stall_bit && !i_stall) o_ce <= 0; //if this stage is stalled but next stage is not, disable 
                                                                    //clock enable of next stage at next clock cycle (pipeline bubble)
        end
        
    end 

    // determine operation used then compute for y output
    always @* begin  
        y_d = 0;
        
        a = (opcode_jal || opcode_auipc)? i_pc:i_rs1;  // a can either be pc or rs1
        b = (opcode_rtype || opcode_branch)? i_rs2:i_imm; // b can either be rs2 or imm 
        
        if(alu_add) y_d = a + b;
        if(alu_sub) y_d = a - b;
        if(alu_slt || alu_sltu) begin
            y_d = {31'b0, (a < b)};
            if(alu_slt) y_d = (a[31] ^ b[31])? {31'b0,a[31]}:y_d;
        end 
        if(alu_xor) y_d = a ^ b;
        if(alu_or)  y_d = a | b;
        if(alu_and) y_d = a & b;
        if(alu_sll) y_d = a << b[4:0];
        if(alu_srl) y_d = a >> b[4:0];
        if(alu_sra) y_d = $signed(a) >>> b[4:0];
        if(alu_eq || alu_neq) begin
            y_d = {31'b0, (a == b)};
            if(alu_neq) y_d = {31'b0,!y_d[0]};
        end
        if(alu_ge || alu_geu) begin
            y_d = {31'b0, (a >= b)};
            if(alu_ge) y_d = (a[31] ^ b[31])? {31'b0, b[31]}:y_d;
        end
    end

    
    //determine o_rd to be saved to baseg and next value of PC
    always @* begin
        o_flush = i_flush; //flush this stage along with the previous stages
        rd_d = 0;
        rd_valid_d = 0;
        o_change_pc = 0;
        o_next_pc = 0;
        wr_rd_d = 0;
        a_pc = i_pc;
        if(!i_flush) begin
            if(opcode_rtype || opcode_itype) rd_d = y_d;
            if(opcode_branch && y_d[0]) begin
                    o_next_pc = sum; //branch iff value of ALU is 1(true)
                    o_change_pc = i_ce; //change PC when ce of this stage is high (o_change_pc is valid)
                    o_flush = i_ce;
            end
            if(opcode_jal || opcode_jalr) begin
                if(opcode_jalr) a_pc = i_rs1;
                o_next_pc = sum; //jump to new PC
                o_change_pc = i_ce; //change PC when ce of this stage is high (o_change_pc is valid)
                o_flush = i_ce;
                rd_d = i_pc + 4; //register the next pc value to destination register
            end 
        end
        if(opcode_lui) rd_d = i_imm;
        if(opcode_auipc) rd_d = sum;

        if(opcode_branch || opcode_store || (opcode_system && i_funct3 == 0) || opcode_fence ) wr_rd_d = 0; //i_funct3==0 are the non-csr system instructions 
        else wr_rd_d = 1; //always write to the destination reg except when instruction is BRANCH or STORE or SYSTEM(except CSR system instruction)  

        if(opcode_load || (opcode_system && i_funct3!=0)) rd_valid_d = 0;  //value of o_rd for load and CSR write is not yet available at this stage
        else rd_valid_d = 1;

        //stall logic (stall when upper stages are stalled, when forced to stall, or when needs to flush previous stages but are still stalled)
        o_stall = (i_stall || i_force_stall) && !i_flush; //stall when alu needs wait time
    end
        
    assign sum = a_pc + i_imm; //share adder for all addition operation for less resource utilization

    `ifdef FORMAL
        // assumption on inputs(not more than one opcode and alu operation is high)
        wire[4:0] f_alu=i_alu[`ADD]+i_alu[`SUB]+i_alu[`SLT]+i_alu[`SLTU]+i_alu[`XOR]+i_alu[`OR]+i_alu[`AND]+i_alu[`SLL]+i_alu[`SRL]+i_alu[`SRA]+i_alu[`EQ]+i_alu[`NEQ]+i_alu[`GE]+i_alu[`GEU]+0;
        wire[4:0] f_opcode=i_opcode[`RTYPE]+i_opcode[`ITYPE]+i_opcode[`LOAD]+i_opcode[`STORE]+i_opcode[`BRANCH]+i_opcode[`JAL]+i_opcode[`JALR]+i_opcode[`LUI]+i_opcode[`AUIPC]+i_opcode[`SYSTEM]+i_opcode[`FENCE];

        always @* begin
            assume(f_alu <= 1);
            assume(f_opcode <= 1);
        end

        // verify all operations with $signed/$unsigned distinctions
        always @* begin 
            if(i_alu[`SLTU]) assert(y_d[0] == $unsigned(a) < $unsigned(b));
            if(i_alu[`SLT]) assert(y_d[0] == $signed(a) < $signed(b));
            if(i_alu[`SLL]) assert($unsigned(y_d) == $unsigned(a) << $unsigned(b[4:0]));
            if(i_alu[`SRL]) assert($unsigned(y_d) == $unsigned(a) >> $unsigned(b[4:0]));
            if(i_alu[`SRA]) assert($signed(y_d) == ($signed(a) >>> $unsigned(b[4:0])));
            if(i_alu[`GEU]) assert(y_d[0] == ($unsigned(a) >= $unsigned(b)));
            if(i_alu[`GE]) assert(y_d[0] == ($signed(a) >= $signed(b)));
        end
        
    `endif
endmodule
