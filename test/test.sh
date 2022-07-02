#! /bin/bash

# Configurables
#INDIVIDUAL_TESTDIR=./riscv-tests/isa/rv32ui  # directory of RISCV testcases used in debug mode (INDIVIDUAL TESTING)
 INDIVIDUAL_TESTDIR=./extra  # directory of RISCV testcases used in debug mode (INDIVIDUAL TESTING)

# Compilation parameters for RISC-V toolchain
PREFIX=riscv64-unknown-elf-
ONAME=test          # executable file name (xxxx.bin)
MEMORY=memory.mem   # memory file name (extracted text and data sections from the executable file),filename used here must also be added to rv32i_soc_TB parameter for assurance
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
    testfiles="./extra/*.s" # My own tests [basic instructions, CSRs, system instructions, exception and interrupt handling]
 
elif [ "$1" == "all" ]
then
    testfiles="./riscv-tests/isa/rv32ui/*.S ./riscv-tests/isa/rv32mi/*.S ./extra/*.s" # Combination of rv32ui, rv32mi, and mytest
    
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
          ../rtl/rv32i_soc.v
          ../test/rv32i_soc_TB.v"

            
countfile=0     # stores total number of testfiles
countpassed=0   # stores total number of PASSED
countfailed=0   # stores total number of FAILED
countunknown=0  # stores total number of UNKNOWN (basereg 0x17 is not 0x0000005d)
countmissing=0  # stores total number of missing testfiles
failedlist=""   # stores lists of testfiles that FAILED
unknownlist=""  # stores lists of testfiles that has UNKNOWN output
missinglist=""  # stores list of testfiles that are missing
 

if [ "$1" == "compile" ] # compile-only the rtl files 
then
    if [ $(command -v vlog) ] 
    then                
        if [ -d "./work/" ]  # check first if work library exists
        then
            vdel -all -lib work # delete old library folder
        fi
        vlib work
        vlog ${rtlfiles}
    else 
        rm -f testbench.vvp # remove previous occurence of vvp file  
        iverilog -I "../rtl/" $rtlfiles
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
            
            ${PREFIX}gcc -c -g -march=rv32g -mabi=ilp32 \
            -I./riscv-tests/env/p -I./riscv-tests/isa/macros/scalar \
            ${testfile} -o ${ONAME}.o

            riscv64-unknown-elf-ld -melf32lriscv -Ttext 0 ${ONAME}.o -o ${ONAME}.bin
            
            printf "DONE!\n"
            ############################################################################################################################
            
            
            ####################################### EXTRACT TEXT AND DATA SECTIONS FROM BIN FILE #######################################
            printf "\textracting text and data sections....."
            if (( $(python3 sections.py ${ONAME}.bin ${MEMORY}| grep DONE -c) != 0 )) # extract text section and data section from bin file
            then
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
                    vlog -quiet +define+HALT_ON_ILLEGAL_INSTRUCTION ${rtlfiles} # current testfile will halt on illegal instruction only
                elif (( $(grep "sbreak" -c <<< $testfile) != 0 )) # if current testfile name has word "sbreak" then that testfile will halt only on ecall
                then
                    vlog -quiet +define+HALT_ON_ECALL ${rtlfiles} # halt core on ecall
                else
                    vlog -quiet ${rtlfiles} # current testfile will halt on both ebreak/ecall 
                fi
                
                a=$(vsim -quiet -batch -G MEMORY="${MEMORY}" rv32i_soc_TB -do "run -all;exit" | grep "PASS:\|FAIL:\|UNKNOWN:" -A1)
            else
                printf "\tsimulating with Icarus Verilog....."
                rm -f testbench.vvp # remove previous occurence of vvp file  

                if (( $(grep "exception" -c <<< $testfile) != 0 )) # if current testfile name has word "exception" then that testfile will not halt on ebreak/ecall
                then
                    iverilog -I "../rtl/" -o testbench.vvp -DHALT_ON_ILLEGAL_INSTRUCTION $rtlfiles # current testfile will halt on illegal instruction only
                elif (( $(grep "sbreak" -c <<< $testfile) != 0 )) # if current testfile name has word "sbreak" then that testfile will halt only on ecall
                then
                    iverilog -I "../rtl/" -o testbench.vvp -DHALT_ON_ECALL $rtlfiles # halt core on ecall
                else
                    iverilog -I "../rtl/" -o testbench.vvp $rtlfiles
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
    printf "\n%s\n\n" "-----------------------------------------------------------"



else    # DEBUG MODE: first argument given is the assembly file to be tested and debugged
    printf "\nPROCESSING: $1\n"
    if [ -f "${INDIVIDUAL_TESTDIR}/${1}" ]   # true if testfile (first argument) exists
    then   
        ########################################## COMPILE TESTFILE WITH RISC-V TOOLCHAIN ##########################################
        printf "\tcompiling assembly file....."
        
        ${PREFIX}gcc -c -g -march=rv32g -mabi=ilp32 \
        -I./riscv-tests/env/p -I./riscv-tests/isa/macros/scalar \
        ${INDIVIDUAL_TESTDIR}/${1} -o ${ONAME}.o

        riscv64-unknown-elf-ld -melf32lriscv -Ttext 0 ${ONAME}.o -o ${ONAME}.bin

        printf "DONE!\n"
        
        
        ############################################################################################################################
        
        
        ####################################### EXTRACT TEXT AND DATA SECTIONS FROM BIN FILE #######################################
        printf "\textracting text and data sections....."
        if (( $(python3 sections.py ${ONAME}.bin ${MEMORY} | grep DONE -c) != 0 )) # extract text section and data section from bin file
        then
            printf "DONE!\n"
        else
            printf "\e[31mERROR!\n\e[0m"
        fi
        printf "\n##############################################################\n"
        riscv64-unknown-elf-objdump -M numeric -D ${ONAME}.bin -h
        printf "\n##############################################################\n"
        ############################################################################################################################
       
       
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
                vlog -quiet +define+HALT_ON_ILLEGAL_INSTRUCTION ${rtlfiles} # current testfile will halt on illegal instruction only      
            elif (( $(grep "sbreak" -c <<< $1) != 0 )) # if current testfile name has word "sbreak" then that testfile will halt only on ecall
            then
                vlog -quiet +define+HALT_ON_ECALL ${rtlfiles} # halt core on ecall
            else
                vlog -quiet ${rtlfiles} # current testfile will halt on both ebreak/ecall 
            fi
            vsim $2 -G MEMORY="${MEMORY}" rv32i_soc_TB -do "do wave.do;run -all"
            a=$(vsim -batch -G MEMORY="${MEMORY}" rv32i_soc_TB -do "run -all;exit" | grep "PASS:\|FAIL:\|UNKNOWN:" -A1)
        else
            printf "\tsimulating with Icarus Verilog.....\n"
            printf "\n##############################################################\n"
            rm -f ./testbench.vvp 

            if (( $(grep "exception" -c <<< $1) != 0 ))
            then
                iverilog -I "../rtl/" -o testbench.vvp -DHALT_ON_ILLEGAL_INSTRUCTION $rtlfiles # current testfile will halt on illegal instruction only
            elif (( $(grep "sbreak" -c <<< $1) != 0 )) # if current testfile name has word "sbreak" then that testfile will halt only on ecall
            then
                iverilog -I "../rtl/" -o testbench.vvp -DHALT_ON_ECALL $rtlfiles # halt core on ecall
            else
                iverilog -I "../rtl/" -o testbench.vvp $rtlfiles # current testfile will halt on both ebreak/ecall 
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

        ############################################################################################################################
    else
        printf "\e[31m\tTESTFILE DOES NOT EXIST\n\n\e[0m"    # testfile is missing
    fi
fi

# HOW TO USE
# $ ./test.sh = use the official tests from RISCV [rv32ui and rv32mi]
# $ ./test.sh compile = compile-only the rtl files
# $ ./test.sh rv32ui = test only the rv32ui official test
# $ ./test.sh rv32mi = test only the rv32mi official test
# $ ./test.sh extra = test only the assembly files inside extra folder [contains tests for interrupts which the official tests don't have]
# $ ./test.sh all = test rv32ui, rv32mi, and mytest
# $ ./test.sh add.S = test and debug testfile "add.S" which is located at INDIVIDUAL_TESTDIR
# $ ./test.sh add.S -gui = test and debug testfile "add.S" and open wave in Modelsim



