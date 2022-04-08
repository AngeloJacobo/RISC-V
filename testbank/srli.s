#
# TEST CODE FOR SRLI
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
       
        
        # 1024 >> 5 = 32 (shift to nonzero value)
        li      x1, 1024        # set x1 to 1024  (0x00000400)
        srli    x2, x1, 5       # shift right logical x1(1024) by 5, x2=32 (0x00000020) 
        
        # 1024 >> 11 = 0 (shift to zero)
        srli    x3, x1, 11      # shift right logical x1(1024) by 11, x3=0 (0x00000000)
        
        # -1024 >> 23 = 511 (shift negative number logically) 
        li      x4, -1024       # set x4 to -1024 (0xFFFFFC00)
        srli    x5, x4, 23      # shift right logical x4(-1024) by 23, x5=511 (0x000001FF)
        
        #self-check  
        li      x6, 32          # set x6 to 32 (expected value for x2)
        beqz    x6, fail0       # make sure x6 has value
        li      x7, 511         # set x7 to 511 (expected value for x5)
        beqz    x7, fail0       # make sure x7 has value
        bne     x2, x6, fail1   # 
        bnez    x3, fail2       # branch to fail if not equal to expected value
        bne     x5, x7, fail3   # 
         
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
        
