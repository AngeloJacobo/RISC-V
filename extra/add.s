#
# TEST CODE FOR ADD
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
        
        # 100 + 150 = 250 (positive answer)
        li      x1, 100         # set x1 to 100 (0x00000064)
        li      x2, 150         # set x2 to 150 (0x00000096)
        add     x3, x1, x2      # add x1(100) to x2(150), x3=250 (0x000000FA) 
        
        # -150 + 100 = -50 (negative answer)
        li      x4, -150        # set x4 to -150 (FFFFFF6A)
        add     x5, x4, x1      # add x4(-150) to x1(100), x5=-50 (0xFFFFFFCE)
        
        # -150 + 150 = 0 (zero answer)
        add     x6, x4, x2      # add x4(-150) to x2(150), x6=0 (0x00000000)
        
        # store result to x0
        add     x0, x1, x2      # x0 must be hardcoded to 0
        
        # self-check  
        li      x7, 250         # set x7 to 250 (expected value for x3)
        beqz    x7, fail0       # make sure x7 has value
        li      x8, -50         # set x8 to -50 (expected value for x5)
        beqz    x8, fail0       # make sure x8 has value
        bne     x7, x3, fail1   #
        bne     x8, x5, fail2   #branch to fail if not equal to expected value
        bne     x0, x6, fail3   #
        bnez    x0, fail4       #
         
         
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
        
        fail4:
        li      a0, 8           # fail code
        li      a7, 93          # reached end of code
        ebreak

        # -----------------------------------------
        # Data section. Note starts at 0x1000, as 
        # set by DATAADDR variable in rv_asm.bat.
        # -----------------------------------------
        .data

        # Data section
data:
        
