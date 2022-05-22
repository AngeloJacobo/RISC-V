#
# TEST CODE FOR SRL
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
        li      x2, 5           # set x2 to 5     (0x00000005)
        srl     x3, x1, x2      # shift right logical x1(1024) by x2(5), x3=32 (0x00000020) 
        
        # 1024 >> 11 = 0 (shift to zero)
        li      x4, 11          # set x4 to 11 (0x0000000B)
        srl     x5, x1, x4      # shift right x1(1024) by x4(11), x5=0 (0x00000000)
        
        # 1024 >> 2021 = 32 (truncate to 5 bits before shifting)
        li      x6, 2021        # set x6 to 2021 (0x000007E5)
        srl     x7, x1, x6      # shift right x1(1024) by 5 (truncate x6(2021) to 5 bits first), x7=32 (0x00000020)
        
         # -1024 >> 23 = 511 (shift negative number logically) 
        li      x8, -1024       # set x8 to -1024 (0xFFFFFC00)
        li      x9, 23          # set x9 to 23 (0x00000017)
        srl     x11, x8, x9     # shift right logical x8(-1024) by x9(23), x11=511 (0x000001FF)
        
        #self-check  
        li      x12, 32         # set x12 to 32 (expected value for x3 and x7)
        beqz    x12, fail0      # make sure x12 has value
        li      x13, 511        # set x13 to 511 (expected value for x11)
        beqz    x13, fail0      # make sure x13 has value
        bne     x3, x12, fail1  # 
        bnez    x5, fail2       # branch to fail if not equal to expected value
        bne     x7, x12, fail3  # 
        bne     x11, x13, fail4 #
         
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
        
