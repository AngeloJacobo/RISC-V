# Compile the code into work
vlog -f files.tcl

# Run the test
vsim -quiet -gui rv32i_soc_TB

# Load previously saved wave signals 
do wave.do

# Start simulation
run -all