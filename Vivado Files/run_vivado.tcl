# run_vivado.tcl
# NOTE:  typical usage would be "vivado -mode tcl -source run_vivado.tcl" 
#
# STEP#0: define output directory area.
#
set outputDir ./runs             
file delete -force ./runs
file mkdir $outputDir
#
# STEP#1: setup design sources and constraints
#
read_verilog  [ glob ../rtl/*.v ]
read_verilog ../test/rv32i_soc.v
read_mem ../test/memory.mem
read_xdc ./Cmod-S7-25-Master.xdc
#
# STEP#2: run synthesis, report utilization and timing estimates, write checkpoint design
#
synth_design -top rv32i_soc -part xc7s25csga225-1
#
# STEP#3: run placement and logic optimzation, report utilization and timing estimates, write checkpoint design
#
opt_design 
place_design 
phys_opt_design 
#
# STEP#4: run router, report actual utilization and timing, write checkpoint design, run drc, write verilog and xdc out
#
route_design 
#
# STEP#5: generate a bitstream
# 
write_bitstream -force $outputDir/rv32i_soc.bit

# Connect to the Digilent Cable on localhost:3121
open_hw_manager
connect_hw_server -url localhost:3121
current_hw_target [get_hw_targets */xilinx_tcf/Digilent/210376AC734EA]
open_hw_target

# Program and Refresh the XC7K325T Device

current_hw_device [lindex [get_hw_devices] 0]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices] 0]
set_property PROGRAM.FILE {./runs/rv32i_soc.bit} [lindex [get_hw_devices] 0]

program_hw_devices [lindex [get_hw_devices] 0]
refresh_hw_device [lindex [get_hw_devices] 0]
quit


