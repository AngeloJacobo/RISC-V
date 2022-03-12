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
add wave -noupdate -divider <NULL>
add wave -noupdate /rv32i_soc_TB/uut/m0/stage_q
add wave -noupdate /rv32i_soc_TB/uut/m0/pc_q
add wave -noupdate /rv32i_soc_TB/uut/m0/inst_q
add wave -noupdate -divider ALU
add wave -noupdate /rv32i_soc_TB/uut/m0/a
add wave -noupdate /rv32i_soc_TB/uut/m0/b
add wave -noupdate /rv32i_soc_TB/uut/m0/y
add wave -noupdate /rv32i_soc_TB/uut/m0/y_q
add wave -noupdate -divider {Decoder Outputs}
add wave -noupdate /rv32i_soc_TB/uut/m0/rs1_addr
add wave -noupdate /rv32i_soc_TB/uut/m0/rs1
add wave -noupdate /rv32i_soc_TB/uut/m0/rs2_addr
add wave -noupdate /rv32i_soc_TB/uut/m0/rs2
add wave -noupdate /rv32i_soc_TB/uut/m0/imm
add wave -noupdate /rv32i_soc_TB/uut/m0/rd_addr
add wave -noupdate /rv32i_soc_TB/uut/m0/opcode
add wave -noupdate /rv32i_soc_TB/uut/m0/op
add wave -noupdate -divider {Basereg and Memory}
add wave -noupdate /rv32i_soc_TB/uut/m0/m0/base_regfile
add wave -noupdate /rv32i_soc_TB/uut/m2/data_regfile
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {236097 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 243
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
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
WaveRestoreZoom {0 ps} {954755 ps}
