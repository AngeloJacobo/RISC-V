//FSM controller for the fetch, decode, execute, memory access, and writeback processes.

`timescale 1ns / 1ps

module rv32i_fsm (
    input wire i_clk,i_rst_n,
    input wire[31:0] i_inst, //instruction
    input wire[31:0] i_pc, //Program Counter
    input wire[31:0] i_rs1, //Source register 1 value
    input wire[31:0] i_rs2, //Source register 2 value
    input wire[31:0] i_imm, //Immediate value
    /// Opcode Type ///
    input wire i_opcode_jal,
    input wire i_opcode_auipc,
    input wire i_opcode_rtype,
    input wire i_opcode_branch,
    output reg[31:0] o_inst_q, //registered instruction
    output reg[2:0] o_stage_q,//current stage
    output reg[31:0] o_a, //value of o_a in ALU
    output reg[31:0] o_b, //value of o_b in ALU
    output wire o_alu_stage, //high if stage is on EXECUTE
    output wire o_memoryaccess_stage, //high if stage is on MEMORYACCESS
    output wire o_writeback_stage, //high if stage is on WRITEBACK
    output wire o_csr_stage, //high if stage is on EXECUTE
    output wire o_done_tick //high for one clock cycle at the end of every instruction
);

    localparam  FETCH = 0,
                DECODE = 1,
                EXECUTE = 2,
                MEMORYACCESS = 3,
                WRITEBACK = 4;

    initial begin
        o_stage_q = FETCH;
        o_inst_q = 0;
    end
    
    reg[2:0] stage_d;//5 stages 
    reg[31:0] inst_d; //instruction

    //register operation
    always @(posedge i_clk, negedge i_rst_n) begin
        if(!i_rst_n) begin
            o_stage_q <= FETCH;
            o_inst_q <= 0;
        end
        else begin
            o_stage_q <= stage_d;
            o_inst_q <= inst_d;
        end
    end

    //5 stage processor unpipelined (FSM)   
    always @* begin
        stage_d = o_stage_q;
        inst_d = o_inst_q;
        o_a = 0;
        o_b = 0; 
        
        case(o_stage_q)
           FETCH: begin //fetch the instruction
                     inst_d = i_inst; 
                     stage_d = DECODE;
                  end

          DECODE: stage_d = EXECUTE; //retrieve i_rs1,i_rs2, and immediate values (output is registered so 1 i_clk delay is needed)

         EXECUTE: begin //ALU operation
                      o_a = (i_opcode_jal || i_opcode_auipc)? i_pc:i_rs1; 
                      o_b = (i_opcode_rtype || i_opcode_branch)? i_rs2:i_imm; 
                      stage_d = MEMORYACCESS;
                  end
                  
    MEMORYACCESS: stage_d = WRITEBACK;  //load/store to data memory if needed (output is registered so 1 i_clk delay is needed)

       WRITEBACK: stage_d = FETCH; //update i_pc value and writeback to rd if needed

         default: stage_d = FETCH;
        endcase
    end
    
    assign o_alu_stage = o_stage_q == EXECUTE;
    assign o_memoryaccess_stage = o_stage_q == MEMORYACCESS;
    assign o_writeback_stage = o_stage_q == WRITEBACK;
    assign o_csr_stage = o_stage_q == MEMORYACCESS;
    assign o_done_tick = stage_d == FETCH && o_stage_q == WRITEBACK; //one instruction is executed
endmodule
