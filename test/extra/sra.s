#
# TEST CODE FOR SRA
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
       
        
        # 1024 >>> 5 = 32 (shift positive number)
        li      x1, 1024        # set x1 to 1024  (0x00000400)
        li      x2, 5           # set x2 to 5     (0x00000005)
        sra     x3, x1, x2      # shift right arithmetic x1(1024) by x2(5), x3=32 (0x00000020) 
        
        # -1024 >>> 5 = -32 (shift negative number)
        li      x4, -1024       # set x4 to -1024 (0xFFFFFC00)
        sra     x5, x4, x2      # shift right arithmetic x4(-1024) by x2(5), x5=-32 (0xFFFFFFE0)
        
        # -1024 >>> 2021 = -32 (truncate to 5 bits before shifting)
        li      x6, 2021        # set x6 to 2021 (0x000007E5)
        sra     x7, x4, x6      # shift right x4(-1024) by 5 (truncate x6(2021) to 5 bits first), x7=-32 (0xFFFFFFE0)
        
        #self-check  
        li      x8, 32          # set x8 to 32 (expected value for x3)
        beqz    x8, fail0       # make sure x8 has value
        li      x9, -32         # set x9 to -32 (expected value for x5 and x7)
        beqz    x9, fail0       # make sure x9 has value
        bne     x3, x8, fail1   # 
        bne     x5, x9, fail2   # branch to fail if not equal to expected value
        bne     x7, x9, fail3   # 
         
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
        
