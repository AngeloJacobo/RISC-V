//combinational logic for the decoding of a 32 bit instruction [DECODE STAGE]

`timescale 1ns / 1ps

module rv32i_decoder(
    input clk,rst_n,
    input wire[31:0] inst, //32 bit instruction
    output reg[4:0] rs1_addr,//address for register source 1
    output reg[4:0] rs2_addr, //address for register source 2
    output reg[4:0] rd_addr, //address for destination address
    output reg[31:0] imm, //extended value for immediate
    output reg[2:0] funct3, //function type
    /// ALU Operations ///
    output reg alu_add, //addition
    output reg alu_sub, //subtraction
    output reg alu_slt, //set if less than
    output reg alu_sltu, //set if less than unsigned      ,
    output reg alu_xor, //bitwise xor
    output reg alu_or,  //bitwise or
    output reg alu_and, //bitwise and
    output reg alu_sll, //shift left logical
    output reg alu_srl, //shift right logical
    output reg alu_sra, //shift right arithmetic
    output reg alu_eq,  //equal
    output reg alu_neq, //not equal
    output reg alu_ge,  //greater than or equal
    output reg alu_geu, //greater than or equal unisgned
    //// Opcode Type ////
    output reg opcode_rtype,
    output reg opcode_itype,
    output reg opcode_load,
    output reg opcode_store,
    output reg opcode_branch,
    output reg opcode_jal,
    output reg opcode_jalr,
    output reg opcode_lui,
    output reg opcode_auipc,
    output reg opcode_system,
    output reg opcode_fence    
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

    localparam ADD  = 3'b000, //ALU operations and its corresponding funct3 code
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

    wire[4:0] rs2_addr_d = inst[24:20];
    wire[4:0] rs1_addr_d = inst[19:15];
    wire[2:0] funct3_d = inst[14:12];
    wire[4:0] rd_addr_d = inst[11:7];
    wire[6:0] opcode = inst[6:0];

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
    
    //register the outputs of this decoder module for shorter combinational timing paths
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            rs1_addr <= 0;
            rs2_addr <= 0;
            rd_addr  <= 0;
            funct3   <= 0;
            imm      <= 0; 
            /// ALU Operation ///
            alu_add  <= 0;
            alu_sub  <= 0;
            alu_slt  <= 0;
            alu_sltu <= 0;
            alu_xor  <= 0;
            alu_or   <= 0;
            alu_and  <= 0;
            alu_sll  <= 0;
            alu_srl  <= 0;
            alu_sra  <= 0;
            alu_eq   <= 0;
            alu_neq  <= 0;
            alu_ge   <= 0;
            alu_geu  <= 0;
            /// Opcode Type ///
            opcode_rtype  <= 0;
            opcode_itype  <= 0;
            opcode_load   <= 0;
            opcode_store  <= 0;
            opcode_branch <= 0;
            opcode_jal    <= 0;
            opcode_jalr   <= 0;
            opcode_lui    <= 0;
            opcode_auipc  <= 0;
            opcode_system <= 0;
            opcode_fence  <= 0;
        end
        else begin
            rs1_addr <= rs1_addr_d;
            rs2_addr <= rs2_addr_d;
            rd_addr  <= rd_addr_d;
            funct3   <= funct3_d;
            imm      <= imm_d;
            /// ALU Operations ////
            alu_add  <= alu_add_d;
            alu_sub  <= alu_sub_d;
            alu_slt  <= alu_slt_d;
            alu_sltu <= alu_sltu_d;
            alu_xor  <= alu_xor_d;
            alu_or   <= alu_or_d; 
            alu_and  <= alu_and_d;
            alu_sll  <= alu_sll_d; 
            alu_srl  <= alu_srl_d;
            alu_sra  <= alu_sra_d;
            alu_eq   <= alu_eq_d; 
            alu_neq  <= alu_neq_d;
            alu_ge   <= alu_ge_d; 
            alu_geu  <= alu_geu_d;
            //// Opcode Type ////
            opcode_rtype  <= opcode == 7'b011_0011;
            opcode_itype  <= opcode == 7'b001_0011;
            opcode_load   <= opcode == 7'b000_0011;
            opcode_store  <= opcode == 7'b010_0011;
            opcode_branch <= opcode == 7'b110_0011;
            opcode_jal    <= opcode == 7'b110_1111;
            opcode_jalr   <= opcode == 7'b110_0111;
            opcode_lui    <= opcode == 7'b011_0111;
            opcode_auipc  <= opcode == 7'b001_0111;
            opcode_system <= opcode == 7'b111_0011;
            opcode_fence  <= opcode == 7'b000_1111;
        end
    end

     //decode operation for ALU and the extended value of immediate
    always @* begin
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
                alu_add_d = funct3_d == ADD ? !inst[30] : 0; //add and sub has same funct3 code
                alu_sub_d = funct3_d == ADD ? inst[30] : 0;      //differs on inst[30]
            end
            else alu_add_d = funct3_d == ADD;
            alu_slt_d = funct3_d == SLT;
            alu_sltu_d = funct3_d == SLTU;
            alu_xor_d = funct3_d == XOR;
            alu_or_d = funct3_d == OR;
            alu_and_d = funct3_d == AND;
            alu_sll_d = funct3_d == SLL;
            alu_srl_d = funct3_d == SRA ? !inst[30]:0; //srl and sra has same funct3 code
            alu_sra_d = funct3_d == SRA ? inst[30]:0 ;      //differs on inst[30]
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

        /************************** extend the immediate (imm) *********************/
        case(opcode)
        I_TYPE , LOAD , JALR: imm_d = {{20{inst[31]}},inst[31:20]}; 
                       STORE: imm_d = {{20{inst[31]}},inst[31:25],inst[11:7]};
                      BRANCH: imm_d = {{19{inst[31]}},inst[31],inst[7],inst[30:25],inst[11:8],1'b0};
                         JAL: imm_d = {{11{inst[31]}},inst[31],inst[19:12],inst[20],inst[30:21],1'b0};
                 LUI , AUIPC: imm_d = {inst[31:12],12'h000};
                     default: imm_d = 0;
        endcase
        /**************************************************************************/
    end
    
endmodule
