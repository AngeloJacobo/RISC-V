#! /bin/bash

FILES="files.tcl"  #file containing all verilog filenames
TOP="rv32i_soc_TB" #top verilog module
SNAPSHOT="snap"    #snapshot file name
WAVE="wave.wcfg"   #wave configuration file

#compile verilog files indiviually
printf "\n/********************************** COMPILE **********************************/\n\n"
xvlog -f $FILES
printf "\n/*****************************************************************************/\n\n"

#elaborate and link the compiled files
printf "\n/********************************** ELABORATE **********************************/\n\n"
xelab -top $TOP -debug typical -snapshot $SNAPSHOT
printf "\n/*****************************************************************************/\n\n"

#simulate the snaphot from elaborate
if [ "$1" == "gui" ]
then
    printf "\n/********************************** SIMULATE **********************************/\n\n"
    xsim $SNAPSHOT -gui -view $WAVE 
    printf "\n/*****************************************************************************/\n\n"
fi

if [ "$1" == "nogui" ]
then
    printf "\n/********************************** SIMULATE **********************************/\n\n"
    xsim $SNAPSHOT -R
    printf "\n/*****************************************************************************/\n\n"
fi

#HOW TO USE:
# ./sim.sh = compile -> elaborate (update snapshot) 
# ./sim.sh gui = compile -> elaborate -> simulate (open GUI and wave config file)
# ./sim.sh nogui = compile -> elaborate -> simulate (run all outputs in bash)


