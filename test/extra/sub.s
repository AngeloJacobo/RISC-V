#
# TEST CODE FOR SUB
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
        
        # 150 - 100 = 50 (positive answer)
        li      x1, 100         # set x1 to 100 (0x00000064)
        li      x2, 150         # set x2 to 150 (0x00000096)
        sub     x3, x2, x1      # subtract x2(150) to x1(100), x3=50 (0x00000032) 
        
        # 100 - 150 = -50 (negative answer)
        sub     x4, x1, x2      # subtract x1(100) to x2(150), x4=-50 (0xFFFFFFCE)
        
        # 0 - (-100) = 100 (negative of negative)
        li      x5, -100        # set x5 to -100 (0xFFFFFF9C)
        sub     x6, x0, x5      # subtract x0(0) to x5(-100), x6=100 (0x00000064)
        
        #self-check  
        li      x7, 50          # set x7 to 50 (expected value for x3)
        beqz    x7, fail0       # make sure x7 has value
        li      x8, -50         # set x8 to -50 (expected value for x4)
        beqz    x8, fail0       # make sure x8 has value
        bne     x7, x3, fail1   #
        bne     x8, x4, fail2   # branch to fail if not equal to expected value
        bne     x1, x6, fail3   #
         
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
        
