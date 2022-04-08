#! /bin/bash

TESTDIR=./testbank  #directory of testcases

#names of testfiles
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
            $TESTDIR/auipc.s"
            
countfile=0     # stores total number of testfiles
countpassed=0   # stores total number of PASSED
countfailed=0   # stores total number of FAILED
countmissing=0  # stores total number of missing testfiles
failedlist=""   # stores lists of testfiles that FAILED
missinglist=""  # stores list of testfiles that are missing

for file in $testfiles      #iterate through all testfiles
do
    printf "PROCESSING: $file\n"
    if [ -f $file ]         # true if testfile exists
    then   
        ./rv_asm.bat $file  # compile testfile 
        if (( $(./rv32.exe -t test.exe -r -e | grep PASS -c) > 0 ))   # Grep and test if the word "PASS" exist from the output of ISS 
        then
            printf "PASSED \n\n"
            countpassed=$((countpassed+1)) # increment number of PASSED
        else    
            printf "FAILED:\n"   
            printf "%s\n" "------------------------------------------------------------------------"
            ./rv32.exe -t test.exe -r -e -x -m 8    # Print the output of ISS with the register dump
            printf "%s\n\n" "------------------------------------------------------------------------"
            countfailed=$((countfailed+1))  # increment number of FAILED
            failedlist="$failedlist \"$file\""  # add name of FAILED testfile 
        fi
        
    else
        printf "TESTFILE DOES NOT EXIST\n\n"    # testfile is missing
        countmissing=$((countmissing+1))        # increment number of missing testfile
        missinglist="$missinglist \"$file\""    # add name of missing testfile
    fi
    countfile=$((countfile+1))  # increment number of total testfile
done

printf "\n%s\n" "--------------------------SUMMARY--------------------------"
printf "$countfile TESTFILES\n"
printf "%s\n" "___________________"
printf "$countpassed PASSED\n"
printf "$countfailed FAILED"

if (($countfailed > 0))     # print names of testfiles that FAILED if > 0
then
    printf ": $failedlist"
fi
printf "\n$countmissing MISSING TESTFILE"
if (($countmissing > 0))    # print names of testfiles that are missing if > 0
then
    printf ": $missinglist"
fi
printf "\n%s\n\n" "-----------------------------------------------------------"

