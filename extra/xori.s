#
# TEST CODE FOR XORI
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
       
        # 100 ^ 150 = 242 (nonzero answer)
        li      x1, 100          # set x1 to 100 (0x00000064)
        xori    x2, x1, 150      # xori x1(100) to 150, x2=242 (0x000000F2) 
        
        # 100 ^ 100 = 0 (zero answer)
        xori    x3, x1, 100      # xor x1(100) to 100, x3=0 (0x00000000)
        
        #self-check  
        li      x4, 242         # set x4 to 242 (expected value for x3)
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
        
