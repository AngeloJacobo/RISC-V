#
# TEST CODE FOR ORI
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
        ori     x2, x1, 150     # ori x1(100) to 150, x2=246 (0x000000F6) 
        
        # -2048 | 2047 = -1 (all ones)
        li      x3, -2048       # set x3 to -2048 (0xFFFFF800)
        ori     x4, x3, 2047    # ori x3(-2048) to 2047, x4=-1 (0xFFFFFFFF)
        
        #self-check  
        li      x5, 246         # set x5 to 246 (expected value for x2)
        beqz    x5, fail0       # make sure x5 has value
        li      x6, -1          # set x6 to -1 (expected value for x4)
        beqz    x6, fail0       # make sure x6 has value
        bne     x2, x5, fail1   #
        bne     x4, x6, fail2   # branch to fail if not equal to expected value
         
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
        
