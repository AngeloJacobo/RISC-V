#
# TEST CODE FOR CSR instructions (CSRRW, CSRRS, CSRRC, CSRRWI, CSRRSI, CSRRCI)
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
        
        
        li      x1, 100             # set x1 to 100 (0x00000064)
        li      x2, 200             # set x2 to 200 (0x000000C8)
        li      x3, 0x10000000      # set x3 to 0x10000000
        
        # Test CSRRW
        csrrw   x4, mtvec, x2       # set mtvec to value of x2 (0x000000C8) and set x4 to current value of mtvec (0x00000064)
        
        # Test CSRRS
        csrrs   x5, mtvec, x3       # set bits in mtvec based on x3 (0x000000C8 | 0x10000000 = 0x100000C8) and set x5 to current value of mtvec (0x000000C8)
        
        # Test CSRRC
        csrrc   x6, mtvec, x2       # clear bits in mtvec based on x2 (0x100000C8 & ~(0x000000C8) = 0x10000000) and set x6 to current value of mtvec (0x100000C8)
        
        # Test CSRRWI
        csrrwi  x7, mtvec, 0b10101  # set mtvec to value of 0b10101 (0x00000015) and set x7 to current value of mtvec (0x10000000)
        
        # Test CSRRSI
        csrrsi  x8, mtvec, 0b01010  # set bits in mtvec based on the imm (0x00000015 | 0x0000000a = 0x0000001F) and set x8 to current value of mtvec (0x00000015)
        
        # Test CSRRCI
        csrrci  x9, mtvec,  0b10000 # clear bits in mtvec based on the imm (0x0000001F & ~0x00000010 = 0x0000000F) and set x9 to current value of mtvec (0x0000001F)
        
        csrr    x11, mtvec          # set x11 to current value of mtvec (0x0000000F)
        
        # self-test
        beqz    x2, fail0           # make sure x1 has value
        bne     x5, x2, fail1       # failed on csrrw
        li      x12, 0x100000C8   
        beqz    x12, fail0          # make sure x12 has value
        bne     x6, x12, fail2      # failed on csrrs
        li      x12, 0x10000000     
        beqz    x12, fail0          # make sure x12 has value
        bne     x12, x7, fail3      #failed on csrrc
        li      x12, 0x00000015     
        beqz    x12, fail0          # make sure x12 has value
        bne     x12, x8, fail4      # failed on csrrwi
        li      x12, 0x0000001F     
        beqz    x12, fail0          # make sure x12 has value
        bne     x12, x9, fail5      # failed on csrrsi
        li      x12, 0x0000000F     
        beqz    x12, fail0          # make sure x12 has value
        bne     x12, x11, fail6     # failed on csrrsi
        
        
         
         
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
        
        fail5:
        li      a0, 10          # fail code
        li      a7, 93          # reached end of code
        ebreak
        
        fail6:
        li      a0, 12          # fail code
        li      a7, 93          # reached end of code
        ebreak
        

        # -----------------------------------------
        # Data section. Note starts at 0x1000, as 
        # set by DATAADDR variable in rv_asm.bat.
        # -----------------------------------------
        .data

        # Data section
data:
        
