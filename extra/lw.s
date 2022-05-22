#
# TEST CODE FOR LW
#
        # -----------------------------------------
        # Program section (known as text)
        # -----------------------------------------
        .text

# Start symbol (must be present), exported as a global symbol.
_start: .global _start

# Export main as a global symbol
        .global main

# Label for entry point of test code
main:
        ### TEST CODE STARTS HERE ###
        # load word with zero imm
        lla  x1, data            # set x1 to data
        addi x1,x1, 8           # set x1 to data + 8
        lw  x2, 0(x1)           # load word from address data to x2, x2=0x11335577
        
        # load word with positive imm
        lw x3, 8(x1)           # load word from address 0x1010 to x3, x3=0xABCDEF19
        
        # load halfword with negative imm
        lw x4, -8(x1)           # load word from address 0x1000 to x4, x4=0x12345678
        
        #self-check
        li x5, 0x11335577       # set x5 to 0x11335577 (expected value for x2)
        beqz x5, fail0          # make sure x5 has value
        li x6, 0xABCDEF19       # set x6 to 0xABCDEF19 (0xFFFFABCD) (expected value for x3)
        beqz x6, fail0          # make sure x6 has value
        li x7, 0x12345678       # set x7 to 0x12345678 (expected value for x4)
        beqz x7, fail0          # make sure x7 has value
        bne x2, x5, fail1       #
        bne x3, x6, fail2       # branch to fail if not equal to expected value
        bne x4, x7, fail3       #
        
        ###    END OF TEST CODE   ###

        # Exit test using RISC-V International's riscv-tests pass/fail criteria
        pass:
        li      a0, 0           # set a0 (x10) to 0 to indicate a pass code
        li      a7, 93          # set a7 (x17) to 93 (5dh) to indicate reached the end of the test
        ebreak
        
        fail0:
        li      a0, 1           # fail code
        li      a7, 93          # reached end of code
        ebreak
        
        fail1:
        li      a0, 2           # fail code
        li      a7, 93          # reached end of code
        ebreak
        
        fail2:
        li      a0, 4           # fail code
        li      a7, 93          # reached end of code
        ebreak
        
        fail3:
        li      a0, 6           # fail code
        li      a7, 93          # reached end of code
        ebreak
        
 
        # -----------------------------------------
        # Data section. Note starts at 0x1000, as 
        # set by DATAADDR variable in rv_asm.bat.
        # -----------------------------------------
        .data
 data: 
        # Data section
        .word 0x12345678    
        .word 0             
        .word 0x11335577    
        .word 0             
        .word 0xABCDEF19    
