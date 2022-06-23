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
        
        # 1 NOP margin between dependent instructions
        
        li      x1, 100         # set x1 to 100 (0x00000064)
        li      x2, 150         # set x2 to 150 (0x00000096)
        add     x3, x1, x2      # add x1(100) to x2(150), x3=250 (0x000000FA)       
        nop
        nop
        nop
        nop
        nop
        nop
        li      x4, 0xFA        # set x4 to 0xFA (expected value for x3) 
        nop
        nop
        nop
        nop
        nop
        nop
        beqz   x4, fail0        # make sure x4 has value
        nop
        nop
        nop
        nop
        nop
        nop
        bne    x3, x4, fail1    # branch to fail if not equal to expected value
        
        # 2 NOP margin between dependent instructions
        li      x1, 100         # set x1 to 100 (0x00000064)
        li      x2, 150         # set x2 to 150 (0x00000096)
        nop
        nop
        add     x3, x1, x2      # add x1(100) to x2(150), x3=250 (0x000000FA)       
        nop
        nop
        nop
        nop
        nop
        nop
        bne    x3, x4, fail2    # branch to fail if not equal to expected value
        
        # 3 NOP margin between dependent instructions
        li      x1, 100         # set x1 to 100 (0x00000064)
        li      x2, 150         # set x2 to 150 (0x00000096)
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
        bne    x3, x4, fail3    # branch to fail if not equal to expected value     
        
        ###    END OF TEST CODE   ###
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
        
