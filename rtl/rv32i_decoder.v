//logic for decoding the 32 bit instruction [DECODE STAGE]

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
    input wire[`STALL_WIDTH-1:0] i_stall, //informs this stage to stall
    output reg o_stall, //informs pipeline to stall
    input wire i_flush, //flush this stage
    output reg o_flush //flush previous stages
);

    localparam R_TYPE = 7'b011_0011, //instruction types and its corresponding opcode
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

    localparam ADD  = 3'b000, //ALU operations and its corresponding o_funct3 code
               SLT  = 3'b010, 
               SLTU = 3'b011,
               XOR  = 3'b100,
               OR   = 3'b110,
               AND  = 3'b111,
               SLL  = 3'b001,
               SRA  = 3'b101,
               EQ   = 3'b000,
               NEQ  = 3'b001,
               LT   = 3'b100,
               GE   = 3'b101,
               LTU  = 3'b110,
               GEU  = 3'b111;
                      
    initial begin
        o_ce = 0;
        o_pc = 0;
        o_rd_addr = 0;
        o_funct3   = 0;
        o_imm      = 0; 
    end

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
    wire stall_bit = i_stall[`DECODER] || i_stall[`ALU] || i_stall[`MEMORYACCESS] || i_stall[`WRITEBACK];

    //register the outputs of this decoder module for shorter combinational timing paths
    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            o_ce       <= 0;
            o_pc       <= 0;
            o_rs1_addr_q <= 0;
            o_rs2_addr_q <= 0;
            o_rd_addr  <= 0;
            o_funct3   <= 0;
            o_imm      <= 0; 
            o_exception <= 0;
            o_opcode <= 0;
            o_alu <= 0;
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
                
                //// Opcode Type ////
                opcode_rtype_d  = opcode == R_TYPE;
                opcode_itype_d  = opcode == I_TYPE;
                opcode_load_d   = opcode == LOAD;
                opcode_store_d  = opcode == STORE;
                opcode_branch_d = opcode == BRANCH;
                opcode_jal_d    = opcode == JAL;
                opcode_jalr_d   = opcode == JALR;
                opcode_lui_d    = opcode == LUI;
                opcode_auipc_d  = opcode == AUIPC;
                opcode_system_d = opcode == SYSTEM;
                opcode_fence_d  = opcode == FENCE;
                
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
                system_noncsr = opcode == SYSTEM && funct3_d == 0 ; //system instruction but not CSR operation
                
                // Check if instruction is illegal    
                valid_opcode = (opcode_rtype_d || opcode_itype_d || opcode_load_d || opcode_store_d || opcode_branch_d || opcode_jal_d || opcode_jalr_d || opcode_lui_d || opcode_auipc_d || opcode_system_d || opcode_fence_d);
                illegal_shift = (opcode_itype_d && (alu_sll_d || alu_srl_d || alu_sra_d)) && i_inst[25];
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
            else if(stall_bit && !i_stall[`ALU]) o_ce <= 0; //if this stage is stalled but next stage is not, disable 
                                                                    //clock enable of next stage at next clock cycle
        end
    end

     //decode operation for ALU and the extended value of immediate
    always @* begin
        o_stall = i_stall[`ALU] || i_stall[`MEMORYACCESS] || i_stall[`WRITEBACK]; //stall when decoder needs wait time
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
        if(opcode == R_TYPE || opcode == I_TYPE) begin
            if(opcode == R_TYPE) begin
                alu_add_d = funct3_d == ADD ? !i_inst[30] : 0; //add and sub has same o_funct3 code
                alu_sub_d = funct3_d == ADD ? i_inst[30] : 0;      //differs on i_inst[30]
            end
            else alu_add_d = funct3_d == ADD;
            alu_slt_d = funct3_d == SLT;
            alu_sltu_d = funct3_d == SLTU;
            alu_xor_d = funct3_d == XOR;
            alu_or_d = funct3_d == OR;
            alu_and_d = funct3_d == AND;
            alu_sll_d = funct3_d == SLL;
            alu_srl_d = funct3_d == SRA ? !i_inst[30]:0; //srl and sra has same o_funct3 code
            alu_sra_d = funct3_d == SRA ? i_inst[30]:0 ;      //differs on i_inst[30]
        end

        else if(opcode == BRANCH) begin
           alu_eq_d = funct3_d == EQ;
           alu_neq_d = funct3_d == NEQ;    
           alu_slt_d = funct3_d == LT;
           alu_ge_d = funct3_d == GE;
           alu_sltu_d = funct3_d == LTU;
           alu_geu_d= funct3_d == GEU;
        end

        else alu_add_d = 1'b1; //add operation for all remaining instructions
        /*********************************************/

        /************************** extend the immediate (o_imm) *********************/
        case(opcode)
        I_TYPE , LOAD , JALR: imm_d = {{20{i_inst[31]}},i_inst[31:20]}; 
                       STORE: imm_d = {{20{i_inst[31]}},i_inst[31:25],i_inst[11:7]};
                      BRANCH: imm_d = {{19{i_inst[31]}},i_inst[31],i_inst[7],i_inst[30:25],i_inst[11:8],1'b0};
                         JAL: imm_d = {{11{i_inst[31]}},i_inst[31],i_inst[19:12],i_inst[20],i_inst[30:21],1'b0};
                 LUI , AUIPC: imm_d = {i_inst[31:12],12'h000};
              SYSTEM , FENCE: imm_d = {20'b0,i_inst[31:20]};   
                     default: imm_d = 0;
        endcase
        /**************************************************************************/
        
    end
    
endmodule
