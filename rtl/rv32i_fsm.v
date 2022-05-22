//FSM controller for the fetch, decode, execute, memory access, and writeback processes.

`timescale 1ns / 1ps

module rv32i_fsm (
    input wire clk,rst_n,
    input wire[31:0] inst, //instruction
    input wire[31:0] pc, //Program Counter
    input wire[31:0] rs1, //Source register 1 value
    input wire[31:0] rs2, //Source register 2 value
    input wire[31:0] imm, //Immediate value
    /// Opcode Type ///
    input wire opcode_jal,
    input wire opcode_auipc,
    input wire opcode_rtype,
    input wire opcode_branch,
    output reg[31:0] inst_q, //registered instruction
    output reg[2:0] stage_q,//current stage
    output reg[31:0] a, //value of a in ALU
    output reg[31:0] b, //value of b in ALU
    output wire alu_stage, //high if stage is on EXECUTE
    output wire memoryaccess_stage, //high if stage is on MEMORYACCESS
    output wire writeback_stage, //high if stage is on WRITEBACK
    output wire csr_stage, //high if stage is on EXECUTE
    output wire done_tick //high for one clock cycle at the end of every instruction
);

    localparam  FETCH = 0,
                DECODE = 1,
                EXECUTE = 2,
                MEMORYACCESS = 3,
                WRITEBACK = 4;

    initial begin
        stage_q = FETCH;
        inst_q = 0;
    end
    
    reg[2:0] stage_d;//5 stages 
    reg[31:0] inst_d; //instruction

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
    
    assign alu_stage = stage_q == EXECUTE;
    assign memoryaccess_stage = stage_q == MEMORYACCESS;
    assign writeback_stage = stage_q == WRITEBACK;
    assign csr_stage = stage_q == MEMORYACCESS;
    assign done_tick = stage_d == FETCH && stage_q == WRITEBACK; //one instruction is executed
endmodule
