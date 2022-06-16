#
# TEST CODE FOR SLL
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
       
        
        # 50 << 5 = 1600 (shift to nonzero value)
        li      x1, 50          # set x1 to 50  (0x00000032)
        li      x2, 5           # set x2 to 5   (0x00000005)
        sll     x3, x1, x2      # shift left x1(50) by x2(5), x3=1600 (0x00000640) 
        
        # 50 << 31 = 0 (shift to zero)
        li      x4, 31          # set x4 to 31 (0x0000001F)
        sll     x5, x1, x4      # shift left x1(50) by x4(31), x5=0 (0x00000000)
        
        # 50 << 2021 = 1600 (truncate to 5 bits before shifting)
        li      x6, 2021        # set x6 to 2021 (0x000007E5)
        sll     x7, x1, x6      # shift left x1(50) by 5 (truncate x6(2021) to 5 bits first), x7=1600 (0x00000640)
        
        #self-check  
        li      x8, 1600        # set x8 to 1600 (expected value for x3 and x7)
        beqz    x8, fail0       # make sure x8 has value
        bne     x3, x8, fail1   # 
        bnez    x5, fail2       # branch to fail if not equal to expected value
        bne     x7, x8, fail3   # 
         
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
        
