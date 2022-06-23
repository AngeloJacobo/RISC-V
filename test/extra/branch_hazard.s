#
# TEST CODE FOR ADD
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
        
        # 100 + 150 = 250 (positive answer)
        li      x1, 100         # set x1 to 100 (0x00000064)
        nop
        nop
        nop
        nop
        nop
        nop
        li      x2, 150         # set x2 to 150 (0x00000096)
        nop
        nop
        nop
        nop
        nop
        nop
        add     x3, x1, x2      # add x1(100) to x2(150), x3=250 (0x000000FA)       
        nop
        nop
        nop
        nop
        nop
        nop
        j   pass
        ###    END OF TEST CODE   ###

        # Exit test using RISC-V International's riscv-tests pass/fail criteria

fail:
        li      a0, 2           # set a0 (x10) to 0 to indicate a pass code
        nop
        nop
        nop
        nop
        nop
        nop
        li      a7, 93          # set a7 (x17) to 93 (5dh) to indicate reached the end of the test
        nop
        nop
        nop
        nop
        nop
        nop
        ebreak
 pass:
        li      a0, 0           # set a0 (x10) to 0 to indicate a pass code
        nop
        nop
        nop
        nop
        nop
        nop
        li      a7, 93          # set a7 (x17) to 93 (5dh) to indicate reached the end of the test
        nop
        nop
        nop
        nop
        nop
        nop
        ebreak
        
        
        
        
        # -----------------------------------------
        # Data section. Note starts at 0x1000, as 
        # set by DATAADDR variable in rv_asm.bat.
        # -----------------------------------------
        .data

        # Data section
data:
        
