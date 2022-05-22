#! /bin/bash

TESTDIR=./testbank  #directory of testcases

# Compilation parameters for RISC-V toolchain
PREFIX=riscv64-unknown-elf-
ONAME=test
TEXTADDR=0
DATAADDR=1000 # Assumed to be 0x1000 to pass all my testcases

# verilog rtl files of the RISC-V core
rtlfiles="./rtl/rv32i_alu.v 
          ./rtl/rv32i_basereg.v 
          ./rtl/rv32i_decoder.v 
          ./rtl/rv32i_memoryaccess.v 
          ./rtl/rv32i_writeback.v
          ./rtl/rv32i_csr.v
          ./rtl/rv32i_fsm.v
          ./rtl/rv32i_core.v
          ./rtl/rv32i_soc.v
          ./rtl/rv32i_soc_TB.v"


# assembly testfiles
testfiles="$TESTDIR/add.s 
            $TESTDIR/sub.s
            $TESTDIR/slt.s
            $TESTDIR/sltu.s
            $TESTDIR/xor.s
            $TESTDIR/or.s
            $TESTDIR/and.s
            $TESTDIR/sll.s
            $TESTDIR/srl.s
            $TESTDIR/sra.s
            
            $TESTDIR/addi.s
            $TESTDIR/slti.s
            $TESTDIR/sltiu.s
            $TESTDIR/xori.s
            $TESTDIR/ori.s
            $TESTDIR/andi.s
            $TESTDIR/slli.s
            $TESTDIR/srli.s
            $TESTDIR/srai.s
            
            $TESTDIR/lb.s
            $TESTDIR/lh.s
            $TESTDIR/lw.s
            $TESTDIR/lbu.s
            $TESTDIR/lhu.s
            
            $TESTDIR/sb.s
            $TESTDIR/sh.s
            $TESTDIR/sw.s
            
            $TESTDIR/beq.s
            $TESTDIR/bne.s
            $TESTDIR/blt.s
            $TESTDIR/bge.s
            $TESTDIR/bltu.s
            $TESTDIR/bgeu.s
            
            $TESTDIR/jal.s
            $TESTDIR/jalr.s
            
            $TESTDIR/lui.s
            $TESTDIR/auipc.s
            
            $TESTDIR/csr_op.s
            $TESTDIR/exceptions.s
            $TESTDIR/interrupts.s"
  

            
countfile=0     # stores total number of testfiles
countpassed=0   # stores total number of PASSED
countfailed=0   # stores total number of FAILED
countunknown=0  # stores total number of UNKNOWN (basereg 0x17 is not 0x0000005d)
countmissing=0  # stores total number of missing testfiles
failedlist=""   # stores lists of testfiles that FAILED
unknownlist=""  # stores lists of testfiles that has UNKNOWN output
missinglist=""  # stores list of testfiles that are missing

if [ "$1" == "" ] # if no argument is given
then
    printf "\n"
    for testfile in $testfiles      #iterate through all testfiles
    do
        countfile=$((countfile+1))  # increment number of total testfile
        printf "${countfile}: PROCESSING: $testfile\n"
        if [ -f $testfile ]         # true if testfile exists
        then   
            ########################################## COMPILE TESTFILE WITH RISC-V TOOLCHAIN ##########################################
            printf "\tcompiling assembly file....."
            ${PREFIX}as -fpic -march=rv32i -aghlms=${TESTDIR}/${ONAME}.list -o ${TESTDIR}/${ONAME}.o ${testfile}
            ${PREFIX}ld ${TESTDIR}/${ONAME}.o -Ttext ${TEXTADDR} -Tdata ${DATAADDR} -melf32lriscv -o ${ONAME}.bin
            printf "DONE!\n"
            ############################################################################################################################
            
            
            ####################################### EXTRACT TEXT AND DATA SECTIONS FROM BIN FILE #######################################
            printf "\textracting text and data sections....."
            if (( $(python sections.py ${ONAME}.bin | grep DONE -c) != 0 )) # extract text section and data section from bin file
            then
                printf "DONE!\n"
            else
                printf "\e[31mERROR!\n\e[0m"
            fi
            ############################################################################################################################
           
           
            ################################################### TESTBENCH SIMULATION ###################################################
            printf "\tsimulating with Modelsim....."
            
            if [ -d "./work/" ]  # check first if work library exists
            then
                vdel -all -lib work # delete old library folder
            fi
            vlib work
            if (( $(grep "exception" -c <<< $testfile) != 0 )) # if current testfile has word "exception" then that testfile will not halt on ebreak/ecall
            then
                vlog -quiet +define+HALT_ON_ILLEGAL_INSTRUCTION ${rtlfiles} # current testfile will halt on illegal instruction only
            else
                vlog -quiet ${rtlfiles} # current testfile will halt on ebreak/ecall only
            fi
            
            a=$(vsim -quiet -batch -G TEXTFILE="./text.bin" -G DATAFILE="./data.bin" -G DATA_STARTADDR=32\'h${DATAADDR} rv32i_soc_TB -do "run -all;exit" | grep "PASS:\|FAIL:\|UNKNOWN")
            if (( $(grep "PASS:" -c <<< $a) != 0 ))
            then
                printf "PASS!\n\n"
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

elif [ "$1" == "compile" ] # only compile the rtl files 
then
    if [ -d "./work/" ]  # check first if work library exists
    then
        vdel -all -lib work # delete old library folder
    fi
    vlib work
    vlog ${rtlfiles}



else    # argument is given (assembly file to be tested and debugged)
    printf "\nPROCESSING: $1\n"
    if [ -f $1 ]         # true if testfile (first argument) exists
    then   
        ########################################## COMPILE TESTFILE WITH RISC-V TOOLCHAIN ##########################################
        printf "\tcompiling assembly file....."
        ${PREFIX}as -fpic -march=rv32i -aghlms=${TESTDIR}/${ONAME}.list -o ${TESTDIR}/${ONAME}.o $1
        ${PREFIX}ld ${TESTDIR}/${ONAME}.o -Ttext ${TEXTADDR} -Tdata ${DATAADDR} -melf32lriscv -o ${ONAME}.bin
        printf "DONE!\n"
        ############################################################################################################################
        
        
        ####################################### EXTRACT TEXT AND DATA SECTIONS FROM BIN FILE #######################################
        printf "\textracting text and data sections....."
        if (( $(python sections.py ${ONAME}.bin | grep DONE -c) != 0 )) # extract text section and data section from bin file
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
        else
            vlog -quiet ${rtlfiles} # current testfile will halt only on ebreak/ecall 
        fi
        vsim $2 -G TEXTFILE="./text.bin" -G DATAFILE="./data.bin" -G DATA_STARTADDR=32\'h${DATAADDR} rv32i_soc_TB -do "do wave.do;run -all"
        a=$(vsim -batch -G TEXTFILE="./text.bin" -G DATAFILE="./data.bin" -G DATA_STARTADDR=32\'h${DATAADDR} rv32i_soc_TB -do "run -all;exit" | grep "PASS:\|FAIL:\|UNKNOWN")
        printf "##############################################################\n"
        if (( $(grep "PASS:" -c <<< $a) != 0 ))
        then
            printf "PASS!\n\n"
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
# $ ./test.sh = test all testcases
# $ ./test.sh ./testbank/add.s = test and debug testfile "./testbank/add.s" 
# $ ./test.sh ./testbank/add.s -gui = test and debug testfile "./testbank/add" and open Modelsim to visualize wave
# $ ./test.sh compile = compile-only the rtl files

