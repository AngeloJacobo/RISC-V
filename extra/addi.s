#
# TEST CODE FOR ADDI
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
        
        # 100 + (150) = 250 (positive answer)
        li      x1, 100         # set x1 to 100 (0x00000064)
        addi    x2, x1, 150     # addi x1(100) to 150, x2=250 (0x000000FA) 
        
        # 100 + (-150) = -50 (negative answer)
        addi    x3, x1, -150    # addi x1(100) to -150, x3=-50 (0xFFFFFFCE)
        
        # -150 + (150) = 0 (zero answer)
        li      x4, -150        # set x4 to -150 (FFFFFF6A)
        addi    x5, x4, 150     # addi x4(-150) to 150, x5=0 (0x00000000)
        
        # self-check  
        li      x6, 250         # set x6 to 250 (expected value for x2)
        beqz    x6, fail0       # make sure x6 has value
        li      x7, -50         # set x7 to -50 (expected value for x3)
        beqz    x7, fail0       # make sure x7 has value
        bne     x6, x2, fail1   #
        bne     x7, x3, fail2   # branch to fail if not equal to expected value
        bnez    x5, fail3       #
         
         
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

        # Data section
data:
        
