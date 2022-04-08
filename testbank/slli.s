#
# TEST CODE FOR SLLI
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
        li      x1, 50         # set x1 to 50  (0x00000032)
        slli    x2, x1, 5      # shift left x1(50) by 5, x2=1600 (0x00000640) 
        
        # 50 << 31 = 0 (shift to zero)
        slli    x3, x1, 31     # shift left x1(50) by 31, x3=0 (0x00000000)
        
        #self-check  
        li      x4, 1600        # set x4 to 1600 (expected value for x2)
        beqz    x4, fail0       # make sure x4 has value
        bne     x2, x4, fail1   # 
        bnez    x3, fail2       # branch to fail if not equal to expected value

         
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
        
