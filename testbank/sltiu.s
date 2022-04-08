#
# TEST CODE FOR SLTIU
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
        sltiu   x2, x1, 150     # unsigned(x1) < unsigned(150) ? , x2=1
        
        # not set
        sltiu   x3, x1, 50      # unsigned(x1) < unsigned(50) ? , x3=0 
        
        # signed number (set)
        li      x4, -150        # set x4 to -150 (0xFFFFFF6A)
        sltiu   x5, x4, -100    # unsigned(x4) < unsigned(-100) ? , x5=1
        
        # signed number (not set)
        sltiu   x6, x4, -200    # unsigned(x4) < unsigned(-200) ? , x6=0
        
        #signed and unsigned  
        sltiu   x7, x1, -100    # unsigned(x1) < unisgned(-100)? , x7=1
        
        #self-check  
        beqz    x2, fail1       #
        bnez    x3, fail2       # 
        beqz    x5, fail3       # branch to fail if not equal to expected value
        bnez    x6, fail4       #
        beqz    x7, fail5       #
 
         
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
        
        fail5:
        li      a0, 10          # fail code
        li      a7, 93          # reached end of code
        ebreak

        # -----------------------------------------
        # Data section. Note starts at 0x1000, as 
        # set by DATAADDR variable in rv_asm.bat.
        # -----------------------------------------
        .data

        # Data section
data:
        
