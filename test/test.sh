#! /bin/bash

# Configurables
#INDIVIDUAL_TESTDIR=./riscv-tests/isa/rv32ui  # directory of RISCV testcases used in debug mode (INDIVIDUAL TESTING)
INDIVIDUAL_TESTDIR=./extra  # directory of RISCV testcases used in debug mode (INDIVIDUAL TESTING)
FREERTOS_HOME="/home/angelo/Music/FreeRTOS" # Home directory of FreeRTOS (cloned from https://github.com/FreeRTOS/FreeRTOS)
FREERTOS_CODE="freertos.c" # C code which will use FreeRTOS 

# Compilation parameters for RISC-V toolchain
PREFIX=riscv64-unknown-elf-
ONAME=test          # executable file name (xxxx.bin)
MEMORY=memory.mem   # memory file name (extracted text and data sections from the executable file),filename used here must also be added to rv32i_soc_TB parameter for assurance
LINKER_SCRIPT=rv32i_linkerscript.ld # linkerscript used by linker to allow user to have control over the layout and memory usage of the program
ENTRY_CODE=entry.s  # contains the "_start" symbol and initialzes the program (setting the stack pointer and then specify jumping to "main")
FPIC="-fpic"        # enable PIC (Position Independent Code)
MARCH="rv32i_zicsr" # specifies the target RISC-V architecture, including the instruction set extensions and microarchitecture features.
MABI="ilp32" # specifies the ABI (Application Binary Interface) that should be used when generating code. 
             # The ABI defines how function calls, stack frames, and other low-level details are handled,
library_files="./lib/*.c" # all custom library files
            
#-nostartfiles = dont include the standard system startup code (useful for creating custom startup code or for embedded systems where the startup code may be platform-specific)
GCC_FLAGS="-march=$MARCH -mabi=$MABI -ffunction-sections -fdata-sections -nostartfiles $FPIC "

#-Wl = pass arguments to linker: 
#       --gc-sections = garbage collection of unused sections
#       -melf32lriscv = sets the target architecture to ELF32 and RISC-V
#       -Ttext,0 = set starting point
#       -Map,linker.map = output linker map 
#-lm = link the math library
#-lc = link the standard C library
#-lgcc = link GCC runtime library (support functions for programs compiled with GCC, such as exception handling and stack unwinding.)
#-lc = it's common to include this flag twice to ensure that any unresolved symbols from the standard C library are resolved.
GCC_FLAGS+="-Wl,--gc-sections -Wl,-melf32lriscv -Wl,-Ttext,0 -Wl,-Map,linker.map -lm -lc -lgcc -lc"
#Note: Starting address of TEXT section is always zero. Starting address of DATA section depends on the testfile assembly

# Check if RISC-V International Testfiles exists on the main folder
if [ ! -d "./riscv-tests/" ]
then
    git clone https://github.com/riscv-software-src/riscv-tests.git --recursive # Clone riscv-tests if it does not exist
    printf "\n%s\n\n" "-----------------------------------------------------------"
fi
   
   
# define assembly testfiles (REGRESSION TESTS)
if [ "$1" == "rv32ui" ] 
then
    testfiles="./riscv-tests/isa/rv32ui/*.S" # RV32 user-level, integer only [All basic RISCV instructions]
    
elif [ "$1" == "rv32mi" ]
then
    testfiles="./riscv-tests/isa/rv32mi/*.S"  # RV32 machine-level, integer only [CSRs,system instructions, and exception handling] 
    
elif [ "$1" == "extra" ]
then
    testfiles="./extra/*.s ./extra/*.c" # My own tests [basic instructions, CSRs, system instructions, exception and interrupt handling]
 
elif [ "$1" == "all" ]
then
    testfiles="./riscv-tests/isa/rv32ui/*.S ./riscv-tests/isa/rv32mi/*.S ./extra/*.s ./extra/*.c" # Combination of rv32ui, rv32mi, and mytest
    
elif [ "$1" == "" ]
then
    testfiles="./riscv-tests/isa/rv32ui/*.S ./riscv-tests/isa/rv32mi/*.S" # Combination of rv32ui and rv32mi tests
fi


###########################################################################################################################################################


# verilog rtl files of the RISC-V core
rtlfiles="../rtl/rv32i_forwarding.v
          ../rtl/rv32i_basereg.v 
          ../rtl/rv32i_fetch.v
          ../rtl/rv32i_decoder.v 
          ../rtl/rv32i_alu.v 
          ../rtl/rv32i_memoryaccess.v 
          ../rtl/rv32i_writeback.v
          ../rtl/rv32i_csr.v
          ../rtl/rv32i_core.v
          ../test/rv32i_soc.v
          ../test/rv32i_soc_TB.v"

            
countfile=0     # stores total number of testfiles
countpassed=0   # stores total number of PASSED
countfailed=0   # stores total number of FAILED
countunknown=0  # stores total number of UNKNOWN (basereg 0x17 is not 0x0000005d)
countmissing=0  # stores total number of missing testfiles
failedlist=""   # stores lists of testfiles that FAILED
unknownlist=""  # stores lists of testfiles that has UNKNOWN output
missinglist=""  # stores list of testfiles that are missing
 
start_time=$SECONDS

if [ "$1" == "compile" ] # compile-only the rtl files 
then
    if [ $(command -v vlog) ] # Modelsim 
    then                
        if [ -d "./work/" ]  # check first if work library exists
        then
            vdel -all -lib work # delete old library folder
        fi
        vlib work
        vlog +incdir+../rtl/ ${rtlfiles}
    else 
        rm -f testbench.vvp # remove previous occurence of vvp file  
        iverilog -I "../rtl/" -DICARUS $rtlfiles
    fi
    
elif [ "$1" == "lint" ] # run formal verification
then
    rtl="../rtl/rv32i_forwarding.v
          ../rtl/rv32i_basereg.v 
          ../rtl/rv32i_fetch.v
          ../rtl/rv32i_decoder.v 
          ../rtl/rv32i_alu.v 
          ../rtl/rv32i_memoryaccess.v 
          ../rtl/rv32i_writeback.v
          ../rtl/rv32i_csr.v
          ../rtl/rv32i_core.v"
          
    verilator -Wall -I"../rtl/"  -DICARUS --lint-only $rtl
    
elif [ "$1" == "formal" ] # run formal verification
then
    sby -f rv32i_core.sby
    elapsed_time=$(( SECONDS-$start_time ))
    if [ -f "rv32i_core/PASS" ]
    then
        eval "printf \"\n\nPROOF: PASS (ELAPSED TIME: $(date -ud "@$elapsed_time" +'%H hr %M min %S sec'))\n\n\""
    else
        eval "printf \"\n\nPROOF: FAIL (ELAPSED TIME: $(date -ud "@$elapsed_time" +'%H hr %M min %S sec'))\n\n\""
    fi


elif [ "$1" == "rv32ui" ] || [ "$1" == "rv32mi" ] || [ "$1" == "extra" ] || [ "$1" == "all" ] || [ "$1" == "" ] # regression tests
then
    printf "\n"
    for testfile in $testfiles      #iterate through all testfiles
    do
        countfile=$((countfile+1))  # increment number of total testfile
        printf "${countfile}: PROCESSING: $testfile\n"
        if [ -f $testfile ]         # true if testfile exists
        then   
            if (( $(grep "scall" -c <<< $testfile) != 0 )) # skip testfile with "scall" on its filename ("scall" loops)
            then
                printf "\tSKIP\n\n"
                countpassed=$((countpassed+1)) # increment number of PASSED (skip is considered pass)
                continue
            fi
            
            ########################################## COMPILE TESTFILE WITH RISC-V TOOLCHAIN ##########################################
            printf "\tcompiling assembly file....."
            
            if [ -d "./obj/" ]  # check first if object folder exists
            then
               rm -r ./obj/ # remove if exists
            fi
            mkdir ./obj # create new object folder

            # collect all files to be compiled
            FILES=""
            FILES+="$library_files "
            FILES+="${testfile} "
            C_INCLUDE+="-I./riscv-tests/env/p -I./riscv-tests/isa/macros/scalar -I./lib" #include when compiling C files
            ASM_INCLUDE+="-I./riscv-tests/env/p -I./riscv-tests/isa/macros/scalar -I./lib" #include when compiling assembly files
            
            #compile all FILES
            for file in $FILES
            do  
                if (( $(grep "\.c" -c <<< $file) != 0 )) # C codes will use C_INCLUDES and have the entry assembly code linked to it
                then
                    INCLUDE=${C_INCLUDE}
                else
                    INCLUDE=${ASM_INCLUDE}
                fi
                    # use parameter expansion to replace all forward-slashes into "_" (so that any C codes from different paths will be 
                    # distinct from each other even if they have the same name) 
                    obj_name=${file//\//_}
                    obj_name=${obj_name//./_}
                    ${PREFIX}gcc -c ${GCC_FLAGS} ${INCLUDE} ${file} -o ./obj/${obj_name}.o 
            done

            #Compile the entry assembly code
            ${PREFIX}gcc -c ${GCC_FLAGS} ${ENTRY_CODE} -o ./obj/entry.out

            if (( $(grep "\.c" -c <<< ${testfile}) != 0 )) # C codes will have the entry assembly code linked to it
            then
                # Link the test file and entry code, then generate the binary file
                # ${PREFIX}ld -melf32lriscv ./obj/*.o ./obj/entry.out -Ttext 0 -o ${ONAME}.bin --script ${LINKER_SCRIPT} -Map linker.map --gc-sections #remove unused object files using --gc-sections
                ${PREFIX}gcc ${GCC_FLAGS} -T ${LINKER_SCRIPT} ./obj/entry.out  ./obj/*.o -o ${ONAME}.bin -lm
            else
                # Link the test file and entry code, then generate the binary file
                # ${PREFIX}ld -melf32lriscv ./obj/*.o -Ttext 0 -o ${ONAME}.bin --script ${LINKER_SCRIPT} -Map linker.map --gc-sections #remove unused object files using --gc-sections
                ${PREFIX}gcc ${GCC_FLAGS} -T ${LINKER_SCRIPT} ./obj/*.o -o ${ONAME}.bin -lm
            fi

            printf "DONE!\n"
            ############################################################################################################################
            
            
            ####################################### EXTRACT TEXT AND DATA SECTIONS FROM BIN FILE #######################################
            printf "\textracting text and data sections....."
            #if (( $(python3 sections.py ${ONAME}.bin ${MEMORY}| grep DONE -c) != 0 )) # extract text section and data section from bin file
            #then
            #    printf "DONE!\n"
            #else
            #    printf "\e[31mERROR!\n\e[0m"
            #fi
            # NOTE: Use elf2hex which is more complete and better than my own python script
            ${PREFIX}elf2hex --bit-width 32 --input ${ONAME}.bin --output ${MEMORY}
            if [ $? -eq 0 ]; then
                printf "DONE!\n"
            else
                printf "\e[31mERROR!\n\e[0m"
            fi
            ############################################################################################################################
           
           
            ################################################### TESTBENCH SIMULATION ###################################################
            if [ $(command -v vlog) ] 
            then                
                printf "\tsimulating with Modelsim....."
                
                if [ -d "./work/" ]  # check first if work library exists
                then
                    vdel -all -lib work # delete old library folder
                fi
                vlib work
                if (( $(grep "exception" -c <<< $testfile) != 0 )) # if current testfile name has word "exception" then that testfile will not halt on ebreak/ecall
                then
                    vlog -quiet +incdir+../rtl/ +define+HALT_ON_ILLEGAL_INSTRUCTION ${rtlfiles} # current testfile will halt on illegal instruction only
                elif (( $(grep "sbreak" -c <<< $testfile) != 0 )) # if current testfile name has word "sbreak" then that testfile will halt only on ecall
                then
                    vlog -quiet +incdir+../rtl/ +define+HALT_ON_ECALL ${rtlfiles} # halt core on ecall
                else
                    vlog -quiet +incdir+../rtl/ ${rtlfiles} # current testfile will halt on both ebreak/ecall 
                fi
                
                a=$(vsim -quiet -batch -G MEMORY="${MEMORY}" rv32i_soc_TB -do "run -all;exit" | grep "PASS:\|FAIL:\|UNKNOWN:" -A1)
            else
                printf "\tsimulating with Icarus Verilog....."
                rm -f testbench.vvp # remove previous occurence of vvp file  

                if (( $(grep "exception" -c <<< $testfile) != 0 )) # if current testfile name has word "exception" then that testfile will not halt on ebreak/ecall
                then
                    iverilog -I "../rtl/" -o testbench.vvp -DHALT_ON_ILLEGAL_INSTRUCTION -DICARUS $rtlfiles # current testfile will halt on illegal instruction only
                elif (( $(grep "sbreak" -c <<< $testfile) != 0 )) # if current testfile name has word "sbreak" then that testfile will halt only on ecall
                then
                    iverilog -I "../rtl/" -o testbench.vvp -DHALT_ON_ECALL -DICARUS $rtlfiles # halt core on ecall
                else
                    iverilog -I "../rtl/" -o testbench.vvp -DICARUS $rtlfiles
                fi
                a=$(vvp -n testbench.vvp | grep "PASS:\|FAIL:\|UNKNOWN:" -A1)
            fi

            if (( $(grep "PASS:" -c <<< $a) != 0 ))
            then
                status=$(tail -n 1 <<< $a)
                printf "PASS! $status\n\n"
                countpassed=$((countpassed+1)) # increment number of PASSED
            elif (( $(grep "FAIL:" -c <<< $a) != 0 ))
            then
                printf "\e[31m$a\n\n\e[0m" # red text for FAILED
                countfailed=$((countfailed+1))  # increment number of FAILED
                failedlist="$failedlist \"$testfile\""  # add name of FAILED testfile 
            else
                printf "\e[31m$a\n\n\e[0m" # red text for UNKNOWN
                countunknown=$((countunknown+1))  # increment number of UNKNOWN
                unknownlist="$unknownlist \"$testfile\""  # add name of UNKNOWN testfile 
            fi
            ############################################################################################################################
            
            
        else
            printf "\e[31m\tTESTFILE DOES NOT EXIST\n\n\e[0m"    # testfile is missing
            countmissing=$((countmissing+1))        # increment number of missing testfile
            missinglist="$missinglist \"$testfile\""    # add name of missing testfile
        fi
        
    done

    elapsed_time=$(( SECONDS-$start_time ))
    printf "\n%s\n" "--------------------------SUMMARY--------------------------"
    printf "$countfile TESTFILES"
    if [ "$1" == "rv32ui" ] 
    then
        printf " [rv32ui] "
    elif [ "$1" == "rv32mi" ] 
    then
        printf " [rv32mi] "
    elif [ "$1" == "extra" ] 
    then
        printf " [extra] "
    elif [ "$1" == "all" ] 
    then
        printf " [rv32ui][rv32mi][extra] "
    elif [ "$1" == "" ]
    then
        printf " [rv32ui][rv32mi] "
    fi
    
    if (($countpassed == $countfile))     # print names of testfiles that FAILED if > 0
    then
        printf " \e[32m(ALL PASSED)\e[0m"
    fi
    printf "\n%s\n" "___________________"
    printf "\n$countpassed PASSED"
    printf "\n$countfailed FAILED"
    if (($countfailed > 0))     # print names of testfiles that FAILED if > 0
    then
        printf ":\e[31m $failedlist\e[0m"
    fi
    printf "\n$countunknown UNKNOWN"
    if (($countunknown > 0))    # print names of testfiles that are UNKNOWN if > 0
    then
        printf ":\e[31m $unknownlist\e[0m"
    fi
    printf "\n$countmissing MISSING TESTFILE"
    if (($countmissing > 0))    # print names of testfiles that are missing if > 0
    then
        printf ":\e[31m $missinglist\e[0m"
    fi
    eval "printf \"\n\nELAPSED TIME: $(date -ud "@$elapsed_time" +'%H hr %M min %S sec')\""
    printf "\n%s\n\n" "-----------------------------------------------------------"


elif [ "$1" == "freertos" ]
then
    printf "\nPROCESSING: FreeRTOS\n"
    
    ########################################## COMPILE FreeRTOS WITH RISC-V TOOLCHAIN ##########################################
    printf "\tcompiling files....." 
    if [ -d "./obj/" ]  # check first if object folder exists
        then
           rm -r ./obj/ # remove if exists
        fi
        mkdir ./obj # create new object folder
  
    # collect all files to be compiled
    # FreeRTOS RISC-V specific
    FILES="$FREERTOS_HOME/FreeRTOS/Source/portable/GCC/RISC-V/*.c "
    FILES+="$FREERTOS_HOME/FreeRTOS/Source/portable/GCC/RISC-V/portASM.S "
    # FreeRTOS core
    FILES+="$FREERTOS_HOME/FreeRTOS/Source/*.c "
    FILES+="$FREERTOS_HOME/FreeRTOS/Source/portable/MemMang/heap_4.c "
    # Custom library files
    FILES+="$library_files "
    # User file
    FILES+="./freertos/${FREERTOS_CODE} "
    
    # FreeRTOS include
    C_INCLUDE="-I $FREERTOS_HOME/FreeRTOS/Source/portable/GCC/RISC-V "
    C_INCLUDE+="-I $FREERTOS_HOME/FreeRTOS/Source/include "
    C_INCLUDE+="-I ./freertos " # freertos_risc_v_chip_specific_extensions header file
    ASM_INCLUDE="-DportasmHANDLE_INTERRUPT=SystemIrqHandler " # handles the external interrupt
    ASM_INCLUDE="-I ./freertos" #freertos_risc_v_chip_specific_extensions header file
    # custom library include
    C_INCLUDE+="-I ./lib/   " 
    
    # Compile each files
    for file in $FILES
        do  
            if (( $(grep "\.c" -c <<< $file) != 0 )) # C codes will use C_INCLUDES and have the entry assembly code linked to it
            then
                INCLUDE=${C_INCLUDE}
            else
                INCLUDE=${ASM_INCLUDE}
            fi
                # use parameter expansion to replace all forward-slashes into "_" (so that any C codes from different paths will be 
                # distinct from each other even if they have the same name) 
                obj_name=${file//\//_}
                obj_name=${obj_name//./_}
                ${PREFIX}gcc -c ${GCC_FLAGS} ${INCLUDE} ${file} -o ./obj/${obj_name}.o 
        done

    #Compile the entry assembly code
    ${PREFIX}gcc -c ${GCC_FLAGS} ${ENTRY_CODE} -o ./obj/entry.out

    # Link the object file including the entry code, then generate the binary file
    ${PREFIX}gcc ${GCC_FLAGS} -T ${LINKER_SCRIPT} ./obj/entry.out ./obj/*.o  -o ${ONAME}.bin -lm

    printf "DONE!\n"
    ############################################################################################################################        


    ####################################### EXTRACT TEXT AND DATA SECTIONS FROM BIN FILE #######################################
    printf "\textracting text and data sections....."

    printf "\n##############################################################\n"
    # Dont print objdump if needs to install to FPGA
    if [ "$2" != "-install" ] 
    then
        ${PREFIX}objdump -M numeric -D ${ONAME}.bin -h 
    fi
    ${PREFIX}elf2hex --bit-width 32 --input ${ONAME}.bin --output ${MEMORY}
    if [ $? -eq 0 ]; then
        printf "DONE!\n"
    else
        printf "\e[31mERROR!\n\e[0m"
    fi
    printf "\n##############################################################\n"
    ############################################################################################################################
    
    ################################################### TESTBENCH SIMULATION ###################################################
    if [ "$2" == "-gui" ]
    then
        printf "\tsimulating with Icarus Verilog.....\n"
        printf "\n##############################################################\n"
        rm -f ./testbench.vvp 

        iverilog -I "../rtl/" -o testbench.vvp -DHALT_ON_EBREAK -DLONGER_SIM_LIMIT -DICARUS $rtlfiles # current testfile will halt on both ebreak/ecall 
        vvp -n testbench.vvp
        if [ "$2" == "-gui" ]
        then
            gtkwave wave.gtkw
        fi
        a=$(vvp -n testbench.vvp | grep "PASS:\|FAIL:\|UNKNOWN:" -A1)
    ############################################################################################################################
    
    ################################################### Install to FPGA Board ###################################################
    #install RISC-V core to FPGA board using current memory.mem 
    elif [ "$2" == "-install" ] 
    then
        cd ../Vivado\ Files
        printf "\nInstalling design to FPGA Board: $1\n"
        vivado -mode tcl -source run_vivado.tcl
    fi
    
    elapsed_time=$(( SECONDS-$start_time ))
    printf "\n\n##############################################################\n"
    eval "printf \"\n\nELAPSED TIME: $(date -ud "@$elapsed_time" +'%H hr %M min %S sec'))\n\n\""
    ############################################################################################################################
    
    
else    # DEBUG MODE: first argument given is the assembly file to be tested and debugged
    printf "\nPROCESSING: $1\n"
    if [ -f "${INDIVIDUAL_TESTDIR}/${1}" ]   # true if testfile (first argument) exists
    then   
        ########################################## COMPILE TESTFILE WITH RISC-V TOOLCHAIN ##########################################
        printf "\tcompiling assembly file....."

        if [ -d "./obj/" ]  # check first if object folder exists
        then
           rm -r ./obj/ # remove if exists
        fi
        mkdir ./obj # create new object folder
        
        # collect all files to be compiled
        FILES+="$library_files "
        FILES+="${INDIVIDUAL_TESTDIR}/${1}  "
        C_INCLUDE+="-I./riscv-tests/env/p -I./riscv-tests/isa/macros/scalar -I./lib" #include when compiling C files
        ASM_INCLUDE+="-I./riscv-tests/env/p -I./riscv-tests/isa/macros/scalar -I./lib" #include when compiling assembly files
        
        # compile each files
        for file in $FILES
        do  
            if (( $(grep "\.c" -c <<< $file) != 0 )) # C codes will use C_INCLUDES and have the entry assembly code linked to it
            then
                INCLUDE=${C_INCLUDE}
            else
                INCLUDE=${ASM_INCLUDE}
            fi
                # use parameter expansion to replace all forward-slashes into "_" (so that any C codes from different paths will be 
                # distinct from each other even if they have the same name) 
                obj_name=${file//\//_}
                obj_name=${obj_name//./_}
                ${PREFIX}gcc -c ${GCC_FLAGS} ${INCLUDE} ${file} -o ./obj/${obj_name}.o 
        done

        #Compile the entry assembly code
        ${PREFIX}gcc -c ${GCC_FLAGS} ${ENTRY_CODE} -o ./obj/entry.out

        if (( $(grep "\.c" -c <<< ${1}) != 0 )) # C codes will have the entry assembly code linked to it
        then
            # Link the test file and entry code, then generate the binary file
            # ${PREFIX}ld -melf32lriscv ./obj/*.o ./obj/entry.out -Ttext 0 -o ${ONAME}.bin --script ${LINKER_SCRIPT} -Map linker.map --gc-sections #remove unused object files using --gc-sections
            ${PREFIX}gcc ${GCC_FLAGS} -T ${LINKER_SCRIPT} ./obj/entry.out ./obj/*.o  -o ${ONAME}.bin -lm
        else
            # Link the test file and entry code, then generate the binary file
            # ${PREFIX}ld -melf32lriscv ./obj/*.o -Ttext 0 -o ${ONAME}.bin --script ${LINKER_SCRIPT} -Map linker.map --gc-sections #remove unused object files using --gc-sections
            ${PREFIX}gcc ${GCC_FLAGS} -T ${LINKER_SCRIPT} ./obj/*.o -o ${ONAME}.bin -lm
        fi

        printf "DONE!\n"      
        ############################################################################################################################
        
        
        ####################################### EXTRACT TEXT AND DATA SECTIONS FROM BIN FILE #######################################
        printf "\textracting text and data sections....."
        
        #if (( $(python3 sections.py ${ONAME}.bin ${MEMORY} | grep DONE -c) != 0 )) # extract text section and data section from bin file
        #then
        #    printf "DONE!\n"
        #else
        #    printf "\e[31mERROR!\n\e[0m"
        #fi
        printf "\n##############################################################\n"
        # Dont print objdump if needs to install to FPGA
        if [ "$2" != "-install" ] 
        then
            ${PREFIX}objdump -M numeric -D ${ONAME}.bin -h 
        fi
        
        #python3 sections.py ${ONAME}.bin ${MEMORY}
        #NOTE: Use elf2hex which is more complete and better than my own python script
        ${PREFIX}elf2hex --bit-width 32 --input ${ONAME}.bin --output ${MEMORY}
        if [ $? -eq 0 ]; then
            printf "DONE!\n"
        else
            printf "\e[31mERROR!\n\e[0m"
        fi
        printf "\n##############################################################\n"
        ############################################################################################################################
       
       
        if [ "$2" != "-nosim" ] && [ "$2" != "-install" ]
        then
        ################################################### TESTBENCH SIMULATION ###################################################
            if [ $(command -v vlog) ]
            then
                printf "\tsimulating with Modelsim.....\n"
                printf "\n##############################################################\n"
                if [ -d "./work/" ]  # check first if work library exists
                then
                    vdel -all -lib work # delete old library folder
                fi
                vlib work
                
                if (( $(grep "exception" -c <<< $1) != 0 ))
                then
                    vlog -quiet +incdir+../rtl/ +define+HALT_ON_ILLEGAL_INSTRUCTION ${rtlfiles} # current testfile will halt on illegal instruction only      
                elif (( $(grep "sbreak" -c <<< $1) != 0 )) # if current testfile name has word "sbreak" then that testfile will halt only on ecall
                then
                    vlog -quiet +incdir+../rtl/ +define+HALT_ON_ECALL ${rtlfiles} # halt core on ecall
                else
                    vlog -quiet +incdir+../rtl/ ${rtlfiles} # current testfile will halt on both ebreak/ecall 
                fi
                vsim $2 -G MEMORY="${MEMORY}" rv32i_soc_TB -do "do wave.do;run -all"
                a=$(vsim -batch -G MEMORY="${MEMORY}" rv32i_soc_TB -do "run -all;exit" | grep "PASS:\|FAIL:\|UNKNOWN:" -A1)
            else
                printf "\tsimulating with Icarus Verilog.....\n"
                printf "\n##############################################################\n"
                rm -f ./testbench.vvp 

                if (( $(grep "exception" -c <<< $1) != 0 ))
                then
                    iverilog -I "../rtl/" -o testbench.vvp -DHALT_ON_ILLEGAL_INSTRUCTION -DICARUS $rtlfiles # current testfile will halt on illegal instruction only
                elif (( $(grep "sbreak" -c <<< $1) != 0 )) # if current testfile name has word "sbreak" then that testfile will halt only on ecall
                then
                    iverilog -I "../rtl/" -o testbench.vvp -DHALT_ON_ECALL -DICARUS $rtlfiles # halt core on ecall
                else
                    iverilog -I "../rtl/" -o testbench.vvp -DICARUS $rtlfiles # current testfile will halt on both ebreak/ecall 
                fi
                vvp -n testbench.vvp
                if [ "$2" == "-gui" ]
                then
                    gtkwave wave.gtkw
                fi
                a=$(vvp -n testbench.vvp | grep "PASS:\|FAIL:\|UNKNOWN:" -A1)
            fi
            printf "##############################################################\n"
            if (( $(grep "PASS:" -c <<< $a) != 0 ))
            then    
                status=$(tail -n 1 <<< $a)
                printf "PASS! $status\n\n"
            elif (( $(grep "FAIL:" -c <<< $a) != 0 ))
            then
                printf "\e[31m$a\n\n\e[0m" # red text for FAILED
            else
                printf "\e[31m$a\n\n\e[0m" # red text for UNKNOWN
            fi
        #install RISC-V core to FPGA board using current memory.mem 
        elif [ "$2" == "-install" ] 
        then
            cd ../Vivado\ Files
            printf "\nInstalling design to FPGA Board: $1\n"
            vivado -mode tcl -source run_vivado.tcl
        fi
        ############################################################################################################################
    else
        printf "\e[31m\tTESTFILE DOES NOT EXIST\n\n\e[0m"    # testfile is missing
    fi
    elapsed_time=$(( SECONDS-$start_time ))
    printf "\n\n##############################################################\n"
    eval "printf \"\n\nELAPSED TIME: $(date -ud "@$elapsed_time" +'%H hr %M min %S sec'))\n\n\""
fi



# HOW TO USE
# $ ./test.sh = use the official tests from RISCV [rv32ui and rv32mi]
# $ ./test.sh compile = compile-only the rtl files
# $ ./test.sh rv32ui = test only the rv32ui official test
# $ ./test.sh rv32mi = test only the rv32mi official test
# $ ./test.sh extra = test only the assembly files inside extra folder [contains tests for interrupts which the official tests don't have]
# $ ./test.sh all = test rv32ui, rv32mi, and mytest
# $ ./test.sh add.S = test and debug testfile "add.S" which is located at INDIVIDUAL_TESTDIR
# $ ./test.sh add.S -gui = test and debug testfile "add.S" and open wave in Icarus
# $ ./test.sh add.S -nosim = compile and debug testfile "add.S" without simulating it
# $ ./test.sh add.S -install = compile and install the design to FPGA board
# $ ./test.sh freertos = compile freertos
# $ ./test.sh freertos -gui = compile and debug freertos and open wave in Icarus
# $ ./test.sh freertos -install = compile and install the design to FPGA board





