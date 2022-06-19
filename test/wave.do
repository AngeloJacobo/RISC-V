onerror {resume}
quietly virtual function -install /rv32i_soc_TB/uut/m0/m6 -env /rv32i_soc_TB/uut/m0/m6 { &{/rv32i_soc_TB/uut/m0/m6/i_is_inst_illegal, /rv32i_soc_TB/uut/m0/m6/is_inst_addr_misaligned, /rv32i_soc_TB/uut/m0/m6/i_is_ecall, /rv32i_soc_TB/uut/m0/m6/i_is_ebreak, /rv32i_soc_TB/uut/m0/m6/is_load_addr_misaligned, /rv32i_soc_TB/uut/m0/m6/is_store_addr_misaligned }} EXCEPTIONS
quietly virtual function -install /rv32i_soc_TB/uut/m0/m6 -env /rv32i_soc_TB/uut/m0/m6 { &{/rv32i_soc_TB/uut/m0/m6/external_interrupt_pending, /rv32i_soc_TB/uut/m0/m6/software_interrupt_pending, /rv32i_soc_TB/uut/m0/m6/timer_interrupt_pending }} INTERRUPTS
quietly WaveActivateNextPane {} 0
add wave -noupdate /rv32i_soc_TB/clk
add wave -noupdate /rv32i_soc_TB/rst_n
add wave -noupdate -divider {Core Interface}
add wave -noupdate /rv32i_soc_TB/uut/m0/o_iaddr
add wave -noupdate /rv32i_soc_TB/uut/m0/i_inst
add wave -noupdate /rv32i_soc_TB/uut/m0/o_daddr
add wave -noupdate /rv32i_soc_TB/uut/m0/i_din
add wave -noupdate /rv32i_soc_TB/uut/m0/o_dout
add wave -noupdate -radix binary /rv32i_soc_TB/uut/m0/o_wr_mask
add wave -noupdate /rv32i_soc_TB/uut/m0/o_wr_en
add wave -noupdate -divider {Core Registers}
add wave -noupdate -group opcode_alu /rv32i_soc_TB/uut/m0/opcode_auipc
add wave -noupdate -group opcode_alu /rv32i_soc_TB/uut/m0/opcode_branch
add wave -noupdate -group opcode_alu /rv32i_soc_TB/uut/m0/opcode_fence
add wave -noupdate -group opcode_alu /rv32i_soc_TB/uut/m0/opcode_itype
add wave -noupdate -group opcode_alu /rv32i_soc_TB/uut/m0/opcode_jal
add wave -noupdate -group opcode_alu /rv32i_soc_TB/uut/m0/opcode_jalr
add wave -noupdate -group opcode_alu /rv32i_soc_TB/uut/m0/opcode_load
add wave -noupdate -group opcode_alu /rv32i_soc_TB/uut/m0/opcode_lui
add wave -noupdate -group opcode_alu /rv32i_soc_TB/uut/m0/opcode_rtype
add wave -noupdate -group opcode_alu /rv32i_soc_TB/uut/m0/opcode_store
add wave -noupdate -group opcode_alu /rv32i_soc_TB/uut/m0/opcode_system
add wave -noupdate -expand -group clock_enable /rv32i_soc_TB/uut/m0/ce_global
add wave -noupdate -expand -group clock_enable /rv32i_soc_TB/uut/m0/ce_fetch
add wave -noupdate -expand -group clock_enable /rv32i_soc_TB/uut/m0/ce_decoder
add wave -noupdate -expand -group clock_enable /rv32i_soc_TB/uut/m0/ce_alu
add wave -noupdate -expand -group clock_enable /rv32i_soc_TB/uut/m0/ce_memoryaccess
add wave -noupdate -expand -group clock_enable /rv32i_soc_TB/uut/m0/ce_writeback
add wave -noupdate -group ALU_op /rv32i_soc_TB/uut/m0/m2/i_alu_add
add wave -noupdate -group ALU_op /rv32i_soc_TB/uut/m0/m2/i_alu_and
add wave -noupdate -group ALU_op /rv32i_soc_TB/uut/m0/m2/i_alu_eq
add wave -noupdate -group ALU_op /rv32i_soc_TB/uut/m0/m2/i_alu_ge
add wave -noupdate -group ALU_op /rv32i_soc_TB/uut/m0/m2/i_alu_geu
add wave -noupdate -group ALU_op /rv32i_soc_TB/uut/m0/m2/i_alu_neq
add wave -noupdate -group ALU_op /rv32i_soc_TB/uut/m0/m2/i_alu_or
add wave -noupdate -group ALU_op /rv32i_soc_TB/uut/m0/m2/i_alu_sll
add wave -noupdate -group ALU_op /rv32i_soc_TB/uut/m0/m2/i_alu_slt
add wave -noupdate -group ALU_op /rv32i_soc_TB/uut/m0/m2/i_alu_sltu
add wave -noupdate -group ALU_op /rv32i_soc_TB/uut/m0/m2/i_alu_sra
add wave -noupdate -group ALU_op /rv32i_soc_TB/uut/m0/m2/i_alu_srl
add wave -noupdate -group ALU_op /rv32i_soc_TB/uut/m0/m2/i_alu_sub
add wave -noupdate -group ALU_op /rv32i_soc_TB/uut/m0/m2/i_alu_xor
add wave -noupdate /rv32i_soc_TB/uut/m0/m4/o_next_pc
add wave -noupdate -divider {Decoder Outputs}
add wave -noupdate /rv32i_soc_TB/uut/m0/rs1_addr
add wave -noupdate /rv32i_soc_TB/uut/m0/rs2_addr
add wave -noupdate /rv32i_soc_TB/uut/m0/rs1
add wave -noupdate /rv32i_soc_TB/uut/m0/rs2
add wave -noupdate -divider ALU
add wave -noupdate /rv32i_soc_TB/uut/m0/m2/a
add wave -noupdate /rv32i_soc_TB/uut/m0/m2/b
add wave -noupdate /rv32i_soc_TB/uut/m0/m2/o_y
add wave -noupdate -divider WriteBack
add wave -noupdate /rv32i_soc_TB/uut/m0/m4/pc
add wave -noupdate /rv32i_soc_TB/uut/m0/m4/o_wr_rd
add wave -noupdate /rv32i_soc_TB/uut/m0/rd_addr_memoryaccess
add wave -noupdate /rv32i_soc_TB/uut/m0/m4/rd_d
add wave -noupdate -divider CSR
add wave -noupdate /rv32i_soc_TB/uut/m0/m6/is_trap
add wave -noupdate /rv32i_soc_TB/uut/m0/m6/is_exception
add wave -noupdate /rv32i_soc_TB/uut/m0/m6/EXCEPTIONS
add wave -noupdate /rv32i_soc_TB/uut/m0/m6/is_interrupt
add wave -noupdate /rv32i_soc_TB/uut/m0/m6/INTERRUPTS
add wave -noupdate /rv32i_soc_TB/uut/m0/m6/o_go_to_trap_q
add wave -noupdate /rv32i_soc_TB/uut/m0/m6/o_return_from_trap_q
add wave -noupdate -group CSR_operation /rv32i_soc_TB/uut/m0/m6/CSRRW
add wave -noupdate -group CSR_operation /rv32i_soc_TB/uut/m0/m6/CSRRS
add wave -noupdate -group CSR_operation /rv32i_soc_TB/uut/m0/m6/CSRRC
add wave -noupdate -group CSR_operation /rv32i_soc_TB/uut/m0/m6/CSRRWI
add wave -noupdate -group CSR_operation /rv32i_soc_TB/uut/m0/m6/CSRRSI
add wave -noupdate -group CSR_operation /rv32i_soc_TB/uut/m0/m6/CSRRCI
add wave -noupdate -group CSR_operation -divider {CSR registers}
add wave -noupdate -group CSR_operation /rv32i_soc_TB/uut/m0/m6/mcause_code
add wave -noupdate -group CSR_operation /rv32i_soc_TB/uut/m0/m6/mcause_intbit
add wave -noupdate -group CSR_operation /rv32i_soc_TB/uut/m0/m6/mcountinhibit_cy
add wave -noupdate -group CSR_operation /rv32i_soc_TB/uut/m0/m6/mcountinhibit_ir
add wave -noupdate -group CSR_operation /rv32i_soc_TB/uut/m0/m6/mcycle
add wave -noupdate -group CSR_operation /rv32i_soc_TB/uut/m0/m6/mepc
add wave -noupdate -group CSR_operation /rv32i_soc_TB/uut/m0/m6/mie_meie
add wave -noupdate -group CSR_operation /rv32i_soc_TB/uut/m0/m6/mie_msie
add wave -noupdate -group CSR_operation /rv32i_soc_TB/uut/m0/m6/mie_mtie
add wave -noupdate -group CSR_operation /rv32i_soc_TB/uut/m0/m6/minstret
add wave -noupdate -group CSR_operation /rv32i_soc_TB/uut/m0/m6/i_minstret_inc
add wave -noupdate -group CSR_operation /rv32i_soc_TB/uut/m0/m6/mip_meip
add wave -noupdate -group CSR_operation /rv32i_soc_TB/uut/m0/m6/mip_msip
add wave -noupdate -group CSR_operation /rv32i_soc_TB/uut/m0/m6/mip_mtip
add wave -noupdate -group CSR_operation /rv32i_soc_TB/uut/m0/m6/mscratch
add wave -noupdate -group CSR_operation /rv32i_soc_TB/uut/m0/m6/mstatus_mie
add wave -noupdate -group CSR_operation /rv32i_soc_TB/uut/m0/m6/mstatus_mpie
add wave -noupdate -group CSR_operation -radix decimal /rv32i_soc_TB/uut/m0/m6/MILLISEC_WRAP
add wave -noupdate -group CSR_operation -radix decimal /rv32i_soc_TB/uut/m0/m6/millisec
add wave -noupdate -group CSR_operation -radix decimal /rv32i_soc_TB/uut/m0/m6/mtime
add wave -noupdate -group CSR_operation /rv32i_soc_TB/uut/m0/m6/mtimecmp
add wave -noupdate -group CSR_operation /rv32i_soc_TB/uut/m0/m6/mtval
add wave -noupdate -group CSR_operation /rv32i_soc_TB/uut/m0/m6/mtvec_base
add wave -noupdate -group CSR_operation /rv32i_soc_TB/uut/m0/m6/mtvec_mode
add wave -noupdate -divider MEMORY
add wave -noupdate /rv32i_soc_TB/uut/m1/MEMORY_DEPTH
add wave -noupdate /rv32i_soc_TB/uut/m1/i_data_addr
add wave -noupdate /rv32i_soc_TB/uut/m1/i_data_in
add wave -noupdate /rv32i_soc_TB/uut/m1/o_data_out
add wave -noupdate /rv32i_soc_TB/uut/m1/i_inst_addr
add wave -noupdate /rv32i_soc_TB/uut/m1/o_inst_out
add wave -noupdate /rv32i_soc_TB/uut/m1/memory_regfile
add wave -noupdate /rv32i_soc_TB/uut/m1/i_wr_en
add wave -noupdate /rv32i_soc_TB/uut/m1/i_wr_mask
add wave -noupdate -divider {Basereg and Memory}
add wave -noupdate /rv32i_soc_TB/uut/m0/m0/base_regfile
add wave -noupdate /rv32i_soc_TB/uut/m1/memory_regfile
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {109704 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 243
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {244811 ps}
