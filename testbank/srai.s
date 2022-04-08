#
# TEST CODE FOR SRAI
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
        srai    x2, x1, 5       # shift right arithmetic x1(1024) by 5, x2=32 (0x00000020) 
        
        # -1024 >>> 5 = -32 (shift negative number)
        li      x3, -1024       # set x3 to -1024 (0xFFFFFC00)
        srai    x4, x3, 5       # shift right arithmetic x3(-1024) by 5, x4=-32 (0xFFFFFFE0)
        
        
        #self-check  
        li      x5, 32          # set x5 to 32 (expected value for x2)
        beqz    x5, fail0       # make sure x5 has value
        li      x6, -32         # set x6 to -32 (expected value for x4)
        beqz    x6, fail0       # make sure x6 has value
        bne     x2, x5, fail1   # 
        bne     x4, x6, fail2   # branch to fail if not equal to expected value
         
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
        
