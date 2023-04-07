/* The rv32i_decoder module is responsible for decoding the 32-bit RISC-V instructions, 
producing the necessary control signals, and extracting the operand addresses and immediate 
values required by the execution stage of the RISC-V processor. It is a crucial component
in the decode stage of the pipeline. This module has several key components:
 - Operand address extraction:
    The module extracts the source and destination register addresses (rs1, rs2, and rd) 
    from the input instruction. These addresses are used to access the register file in 
    the next stage of the pipeline.
 - Immediate value extraction: Depending on the instruction type, this module extracts 
    and sign-extends the immediate value (imm) from the input instruction. This value is
    used as an operand for arithmetic or load/store instructions, or as an offset for 
    branch and jump instructions.
 - ALU operation decoding: The module decodes the required ALU operation based on the 
    opcode and funct3 fields of the instruction. It sets the appropriate signals 
    (alu_add_d, alu_sub_d, alu_slt_d, etc.) to indicate the desired operation to be 
    executed in the ALU during the execution stage.
 - Opcode type decoding: The module identifies the type of instruction based on its opcode 
    (opcode_rtype_d, opcode_itype_d, opcode_load_d, etc.). These signals are used in the 
    next stages of the pipeline to control the flow of data and determine the required 
    operations.
 - Exception decoding: The module checks for illegal instructions, system instructions 
    (ECALL, EBREAK, and MRET), and unsupported shift operations. If any of these conditions 
    are detected, the corresponding exception signals (o_exception) are set.
 - Pipeline control: The module supports pipeline stalling and flushing. If the next stage 
    of the pipeline is stalled (i_stall), the module will stall the decode stage (o_stall) 
    and prevent updating the output registers. If a flush signal (i_flush) is received, the 
    module will flush its internal state and disable the clock enable signal (o_ce) for the 
    next stage.
*/

`timescale 1ns / 1ps
`default_nettype none
`include "rv32i_header.vh"

module rv32i_decoder(
    input wire i_clk,i_rst_n,
    input wire[31:0] i_inst, //32 bit instruction
    input wire[31:0] i_pc, //PC value from previous stage
    output reg[31:0] o_pc, //PC value
    output wire[4:0] o_rs1_addr,//address for register source 1
    output reg[4:0] o_rs1_addr_q,//registered address for register source 1
    output wire[4:0] o_rs2_addr, //address for register source 2
    output reg[4:0] o_rs2_addr_q, //registered address for register source 2
    output reg[4:0] o_rd_addr, //address for destination address
    output reg[31:0] o_imm, //extended value for immediate
    output reg[2:0] o_funct3, //function type
    output reg[`ALU_WIDTH-1:0] o_alu, //alu operation type
    output reg[`OPCODE_WIDTH-1:0] o_opcode, //opcode type
    output reg[`EXCEPTION_WIDTH-1:0] o_exception, //exceptions: illegal inst, ecall, ebreak, mret
    /// Pipeline Control ///
    input wire i_ce, // input clk enable for pipeline stalling of this stage
    output reg o_ce, // output clk enable for pipeline stalling of next stage
    input wire i_stall, //informs this stage to stall
    output reg o_stall, //informs pipeline to stall
    input wire i_flush, //flush this stage
    output reg o_flush //flush previous stages
);

    assign o_rs2_addr = i_inst[24:20]; //o_rs1_addrando_rs2_addr are not registered 
    assign o_rs1_addr = i_inst[19:15];   //since rv32i_basereg module do the registering itself
    

    wire[2:0] funct3_d = i_inst[14:12];
    wire[6:0] opcode = i_inst[6:0];

    reg[31:0] imm_d;
    reg alu_add_d;
    reg alu_sub_d;
    reg alu_slt_d;
    reg alu_sltu_d;
    reg alu_xor_d;
    reg alu_or_d;
    reg alu_and_d;
    reg alu_sll_d;
    reg alu_srl_d;
    reg alu_sra_d;
    reg alu_eq_d; 
    reg alu_neq_d;
    reg alu_ge_d; 
    reg alu_geu_d;
    
    reg opcode_rtype_d;
    reg opcode_itype_d;
    reg opcode_load_d;
    reg opcode_store_d;
    reg opcode_branch_d;
    reg opcode_jal_d;
    reg opcode_jalr_d;
    reg opcode_lui_d;
    reg opcode_auipc_d;
    reg opcode_system_d;
    reg opcode_fence_d;
            
    reg system_noncsr = 0;
    reg valid_opcode = 0;
    reg illegal_shift = 0;
    wire stall_bit = o_stall || i_stall; //stall this stage when next stages are stalled

    //register the outputs of this decoder module for shorter combinational timing paths
    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            o_ce <= 0;
        end
        else begin
            if(i_ce && !stall_bit) begin //update registers only if this stage is enabled and pipeline is not stalled
                o_pc       <= i_pc;
                o_rs1_addr_q <= o_rs1_addr;
                o_rs2_addr_q <= o_rs2_addr;
                o_rd_addr  <= i_inst[11:7];
                o_funct3   <= funct3_d;
                o_imm      <= imm_d;
                
                /// ALU Operations ////
                o_alu[`ADD]  <= alu_add_d;
                o_alu[`SUB]  <= alu_sub_d;
                o_alu[`SLT]  <= alu_slt_d;
                o_alu[`SLTU] <= alu_sltu_d;
                o_alu[`XOR]  <= alu_xor_d;
                o_alu[`OR]   <= alu_or_d; 
                o_alu[`AND]  <= alu_and_d;
                o_alu[`SLL]  <= alu_sll_d; 
                o_alu[`SRL]  <= alu_srl_d;
                o_alu[`SRA]  <= alu_sra_d;
                o_alu[`EQ]   <= alu_eq_d; 
                o_alu[`NEQ]  <= alu_neq_d;
                o_alu[`GE]   <= alu_ge_d; 
                o_alu[`GEU]  <= alu_geu_d;
                          
                o_opcode[`RTYPE]  <= opcode_rtype_d;
                o_opcode[`ITYPE]  <= opcode_itype_d;
                o_opcode[`LOAD]   <= opcode_load_d;
                o_opcode[`STORE]  <= opcode_store_d;
                o_opcode[`BRANCH] <= opcode_branch_d;
                o_opcode[`JAL]    <= opcode_jal_d;
                o_opcode[`JALR]   <= opcode_jalr_d;
                o_opcode[`LUI]    <= opcode_lui_d;
                o_opcode[`AUIPC]  <= opcode_auipc_d;
                o_opcode[`SYSTEM] <= opcode_system_d;
                o_opcode[`FENCE]  <= opcode_fence_d;
                
                /*********************** decode possible exceptions ***********************/
                o_exception[`ILLEGAL] <= !valid_opcode || illegal_shift;

                // Check if ECALL
                o_exception[`ECALL] <= (system_noncsr && i_inst[21:20]==2'b00)? 1:0;
                
                // Check if EBREAK
                o_exception[`EBREAK] <= (system_noncsr && i_inst[21:20]==2'b01)? 1:0;
                
                // Check if MRET
                 o_exception[`MRET] <= (system_noncsr && i_inst[21:20]==2'b10)? 1:0;
                /***************************************************************************/
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
    always @* begin
        //// Opcode Type ////
        opcode_rtype_d  = opcode == `OPCODE_RTYPE;
        opcode_itype_d  = opcode == `OPCODE_ITYPE;
        opcode_load_d   = opcode == `OPCODE_LOAD;
        opcode_store_d  = opcode == `OPCODE_STORE;
        opcode_branch_d = opcode == `OPCODE_BRANCH;
        opcode_jal_d    = opcode == `OPCODE_JAL;
        opcode_jalr_d   = opcode == `OPCODE_JALR;
        opcode_lui_d    = opcode == `OPCODE_LUI;
        opcode_auipc_d  = opcode == `OPCODE_AUIPC;
        opcode_system_d = opcode == `OPCODE_SYSTEM;
        opcode_fence_d  = opcode == `OPCODE_FENCE;
        
        /*********************** decode possible exceptions ***********************/
        system_noncsr = opcode == `OPCODE_SYSTEM && funct3_d == 0 ; //system instruction but not CSR operation
        
        // Check if instruction is illegal    
        valid_opcode = (opcode_rtype_d || opcode_itype_d || opcode_load_d || opcode_store_d || opcode_branch_d || opcode_jal_d || opcode_jalr_d || opcode_lui_d || opcode_auipc_d || opcode_system_d || opcode_fence_d);
        illegal_shift = (opcode_itype_d && (alu_sll_d || alu_srl_d || alu_sra_d)) && i_inst[25];
    end

     //decode operation for ALU and the extended value of immediate
    always @* begin
        o_stall = i_stall; //stall previous stage when decoder needs wait time
        o_flush = i_flush; //flush this stage along with the previous stages 
        imm_d = 0;
        alu_add_d = 0;
        alu_sub_d = 0;
        alu_slt_d = 0;
        alu_sltu_d = 0;
        alu_xor_d = 0;
        alu_or_d = 0;
        alu_and_d = 0;
        alu_sll_d = 0;
        alu_srl_d = 0;
        alu_sra_d = 0;
        alu_eq_d = 0; 
        alu_neq_d = 0;
        alu_ge_d = 0; 
        alu_geu_d = 0;
        
        /********** Decode ALU Operation **************/
        if(opcode == `OPCODE_RTYPE || opcode == `OPCODE_ITYPE) begin
            if(opcode == `OPCODE_RTYPE) begin
                alu_add_d = funct3_d == `FUNCT3_ADD ? !i_inst[30] : 0; //add and sub has same o_funct3 code
                alu_sub_d = funct3_d == `FUNCT3_ADD ? i_inst[30] : 0;      //differs on i_inst[30]
            end
            else alu_add_d = funct3_d == `FUNCT3_ADD;
            alu_slt_d = funct3_d == `FUNCT3_SLT;
            alu_sltu_d = funct3_d == `FUNCT3_SLTU;
            alu_xor_d = funct3_d == `FUNCT3_XOR;
            alu_or_d = funct3_d == `FUNCT3_OR;
            alu_and_d = funct3_d == `FUNCT3_AND;
            alu_sll_d = funct3_d == `FUNCT3_SLL;
            alu_srl_d = funct3_d == `FUNCT3_SRA ? !i_inst[30]:0; //srl and sra has same o_funct3 code
            alu_sra_d = funct3_d == `FUNCT3_SRA ? i_inst[30]:0 ;      //differs on i_inst[30]
        end

        else if(opcode == `OPCODE_BRANCH) begin
           alu_eq_d = funct3_d == `FUNCT3_EQ;
           alu_neq_d = funct3_d == `FUNCT3_NEQ;    
           alu_slt_d = funct3_d == `FUNCT3_LT;
           alu_ge_d = funct3_d == `FUNCT3_GE;
           alu_sltu_d = funct3_d == `FUNCT3_LTU;
           alu_geu_d= funct3_d == `FUNCT3_GEU;
        end

        else alu_add_d = 1'b1; //add operation for all remaining instructions
        /*********************************************/

        /************************** extend the immediate (o_imm) *********************/
        case(opcode)
        `OPCODE_ITYPE , `OPCODE_LOAD , `OPCODE_JALR: imm_d = {{20{i_inst[31]}},i_inst[31:20]}; 
                                      `OPCODE_STORE: imm_d = {{20{i_inst[31]}},i_inst[31:25],i_inst[11:7]};
                                     `OPCODE_BRANCH: imm_d = {{19{i_inst[31]}},i_inst[31],i_inst[7],i_inst[30:25],i_inst[11:8],1'b0};
                                        `OPCODE_JAL: imm_d = {{11{i_inst[31]}},i_inst[31],i_inst[19:12],i_inst[20],i_inst[30:21],1'b0};
                        `OPCODE_LUI , `OPCODE_AUIPC: imm_d = {i_inst[31:12],12'h000};
                     `OPCODE_SYSTEM , `OPCODE_FENCE: imm_d = {20'b0,i_inst[31:20]};   
                     default: imm_d = 0;
        endcase
        /**************************************************************************/
        
    end
    
endmodule
