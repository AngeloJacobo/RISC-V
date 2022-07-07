onerror {resume}
quietly virtual signal -install /rv32i_soc_TB/uut/m0 { (context /rv32i_soc_TB/uut/m0 )&{fetch_ce , decoder_ce , alu_ce , memoryaccess_ce , writeback_ce }} clock_enables
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
add wave -noupdate -radix binary /rv32i_soc_TB/uut/m0/stall
add wave -noupdate /rv32i_soc_TB/uut/m0/m2/o_opcode
add wave -noupdate /rv32i_soc_TB/uut/m0/m2/o_alu
add wave -noupdate /rv32i_soc_TB/uut/m0/clock_enables
add wave -noupdate /rv32i_soc_TB/uut/m0/alu_change_pc
add wave -noupdate /rv32i_soc_TB/uut/m0/alu_next_pc
add wave -noupdate /rv32i_soc_TB/uut/m0/writeback_change_pc
add wave -noupdate /rv32i_soc_TB/uut/m0/writeback_next_pc
add wave -noupdate -divider {Decoder Outputs}
add wave -noupdate /rv32i_soc_TB/uut/m0/rs1
add wave -noupdate /rv32i_soc_TB/uut/m0/rs2
add wave -noupdate /rv32i_soc_TB/uut/m0/decoder_rs1_addr
add wave -noupdate /rv32i_soc_TB/uut/m0/decoder_rs2_addr
add wave -noupdate /rv32i_soc_TB/uut/m0/decoder_rd_addr
add wave -noupdate /rv32i_soc_TB/uut/m0/m2/valid_opcode
add wave -noupdate /rv32i_soc_TB/uut/m0/m2/illegal_shift
add wave -noupdate -divider ALU
add wave -noupdate /rv32i_soc_TB/uut/m0/rs1_orig
add wave -noupdate /rv32i_soc_TB/uut/m0/rs2_orig
add wave -noupdate /rv32i_soc_TB/uut/m0/m3/a
add wave -noupdate /rv32i_soc_TB/uut/m0/m3/b
add wave -noupdate /rv32i_soc_TB/uut/m0/m3/o_y
add wave -noupdate -divider WriteBack
add wave -noupdate /rv32i_soc_TB/uut/m0/m5/o_wr_rd
add wave -noupdate -divider {Basereg and Memory}
add wave -noupdate /rv32i_soc_TB/uut/m0/m0/base_regfile
add wave -noupdate /rv32i_soc_TB/uut/m1/memory_regfile
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {236501 ps} 0}
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
WaveRestoreZoom {218274 ps} {320091 ps}
