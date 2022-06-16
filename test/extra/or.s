#
# TEST CODE FOR OR
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
       
        # 100 | 150 = 246 (nonzero answer)
        li      x1, 100         # set x1 to 100 (0x00000064)
        li      x2, 150         # set x2 to 150 (0x00000096)
        or      x3, x1, x2      # or x1(100) to x2(150), x3=246 (0x000000F6) 
        
        # -2048 | 2047 = -1 (all ones)
        li      x4, -2048       # set x4 to -2048 (0xFFFFF800)
        li      x5, 2047        # set x5 to 2047  (0x000007FF)
        or      x6, x4, x5      # or x4(-2048) to x5(2047), x6=-1 (0xFFFFFFFF)
        
        #self-check  
        li      x7, 246         # set x7 to 246 (expected value for x3)
        beqz    x7, fail0       # make sure x7 has value
        li      x8, -1          # set x8 to -1 (expected value for x6)
        beqz    x8, fail0       # make sure x8 has value
        bne     x3, x7, fail1   #
        bne     x6, x8, fail2   # branch to fail if not equal to expected value
         
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
        
        # -----------------------------------------
        # Data section. Note starts at 0x1000, as 
        # set by DATAADDR variable in rv_asm.bat.
        # -----------------------------------------
        .data

        # Data section
data:
        
