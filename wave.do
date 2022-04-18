onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /rv32i_soc_TB/clk
add wave -noupdate /rv32i_soc_TB/rst_n
add wave -noupdate -divider {Core Interface}
add wave -noupdate /rv32i_soc_TB/uut/m0/iaddr
add wave -noupdate /rv32i_soc_TB/uut/m0/inst
add wave -noupdate /rv32i_soc_TB/uut/m0/daddr
add wave -noupdate /rv32i_soc_TB/uut/m0/din
add wave -noupdate /rv32i_soc_TB/uut/m0/dout
add wave -noupdate -radix binary /rv32i_soc_TB/uut/m0/wr_mask
add wave -noupdate /rv32i_soc_TB/uut/m0/wr_en
add wave -noupdate -divider {Core Registers}
add wave -noupdate -radix hexadecimal /rv32i_soc_TB/uut/m0/stage_q
add wave -noupdate /rv32i_soc_TB/uut/m0/inst_q
add wave -noupdate -group opcode /rv32i_soc_TB/uut/m0/opcode_auipc
add wave -noupdate -group opcode /rv32i_soc_TB/uut/m0/opcode_branch
add wave -noupdate -group opcode /rv32i_soc_TB/uut/m0/opcode_fence
add wave -noupdate -group opcode /rv32i_soc_TB/uut/m0/opcode_itype
add wave -noupdate -group opcode /rv32i_soc_TB/uut/m0/opcode_jal
add wave -noupdate -group opcode /rv32i_soc_TB/uut/m0/opcode_jalr
add wave -noupdate -group opcode /rv32i_soc_TB/uut/m0/opcode_load
add wave -noupdate -group opcode /rv32i_soc_TB/uut/m0/opcode_lui
add wave -noupdate -group opcode /rv32i_soc_TB/uut/m0/opcode_rtype
add wave -noupdate -group opcode /rv32i_soc_TB/uut/m0/opcode_store
add wave -noupdate -group opcode /rv32i_soc_TB/uut/m0/opcode_system
add wave -noupdate -group alu_operation /rv32i_soc_TB/uut/m0/alu_add
add wave -noupdate -group alu_operation /rv32i_soc_TB/uut/m0/alu_and
add wave -noupdate -group alu_operation /rv32i_soc_TB/uut/m0/alu_eq
add wave -noupdate -group alu_operation /rv32i_soc_TB/uut/m0/alu_ge
add wave -noupdate -group alu_operation /rv32i_soc_TB/uut/m0/alu_geu
add wave -noupdate -group alu_operation /rv32i_soc_TB/uut/m0/alu_neq
add wave -noupdate -group alu_operation /rv32i_soc_TB/uut/m0/alu_or
add wave -noupdate -group alu_operation /rv32i_soc_TB/uut/m0/alu_sll
add wave -noupdate -group alu_operation /rv32i_soc_TB/uut/m0/alu_slt
add wave -noupdate -group alu_operation /rv32i_soc_TB/uut/m0/alu_sltu
add wave -noupdate -group alu_operation /rv32i_soc_TB/uut/m0/alu_sra
add wave -noupdate -group alu_operation /rv32i_soc_TB/uut/m0/alu_srl
add wave -noupdate -group alu_operation /rv32i_soc_TB/uut/m0/alu_sub
add wave -noupdate -group alu_operation /rv32i_soc_TB/uut/m0/alu_xor
add wave -noupdate -divider {Decoder Outputs}
add wave -noupdate /rv32i_soc_TB/uut/m0/rs1_addr
add wave -noupdate /rv32i_soc_TB/uut/m0/rs1
add wave -noupdate /rv32i_soc_TB/uut/m0/rs2_addr
add wave -noupdate /rv32i_soc_TB/uut/m0/rs2
add wave -noupdate /rv32i_soc_TB/uut/m0/imm
add wave -noupdate /rv32i_soc_TB/uut/m0/rd_addr
add wave -noupdate -divider ALU
add wave -noupdate -radix decimal /rv32i_soc_TB/uut/m0/a
add wave -noupdate -radix decimal /rv32i_soc_TB/uut/m0/b
add wave -noupdate -radix decimal /rv32i_soc_TB/uut/m0/y
add wave -noupdate -divider WriteBack
add wave -noupdate /rv32i_soc_TB/uut/m0/m4/pc
add wave -noupdate /rv32i_soc_TB/uut/m0/m4/rd
add wave -noupdate /rv32i_soc_TB/uut/m0/m4/wr_rd
add wave -noupdate -divider {Basereg and Memory}
add wave -noupdate /rv32i_soc_TB/uut/m0/m0/base_regfile
add wave -noupdate /rv32i_soc_TB/uut/m2/data_regfile
add wave -noupdate /rv32i_soc_TB/uut/m1/inst_regfile
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {182248 ps} 0}
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
WaveRestoreZoom {0 ps} {433823 ps}
