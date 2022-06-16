#
# TEST CODE FOR SLT
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
        
        # set
        li      x1, 100         # set x1 to 100 (0x00000064)
        li      x2, 150         # set x2 to 150 (0x00000096)
        slt     x3, x1, x2      # x1 < x2 ? , x3=1
        
        # not set
        slt     x4, x2, x1      # x2 < x1 ? , x4=0 
        
        # signed number (set)
        li      x5, -100        # set x5 to -100 (0xFFFFFF9C)
        li      x6, -150        # set x6 to -150 (0xFFFFFF6A)
        slt     x7, x6, x5      # x6 < x5 ? , x7=1
        
        # signed number (not set)
        slt     x8, x5, x6      # x5 < x6 ? , x8=0
        
        #self-check  
        beqz    x3, fail1       #
        bnez    x4, fail2       # branch to fail if not equal to expected value
        beqz    x7, fail3       #
        bnez    x8, fail4       #
 
         
        ###    END OF TEST CODE   ###

        # Exit test using RISC-V International's riscv-tests pass/fail criteria
        pass:
        li      a0, 0           # set a0 (x10) to 0 to indicate a pass code
        li      a7, 93          # set a7 (x17) to 93 (5dh) to indicate reached the end of the test
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
        
