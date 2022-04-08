#
# TEST CODE FOR JAL
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
        
        # jump 
        nop                     # no operation
        nop                     # no operation
        jal     x1, jump1       # jump to jump1 then store next PC to x1 , x1=x1_val
        x1_val:
        j       fail1           # jump to fail
        nop                     # no operation
        nop                     # no operation
        
        jump1: 
        nop                     # no operation
        nop                     # no operation
        jal     x2, jump2       # jump to jump2 then store next PC to x2, x2=x2_val
        x2_val:
        jal     fail2           # jump to fail
        nop                     # no operation
        nop                     # no operation
        
        jump2:
        lla     x3, x1_val      # load address of x1_val to x3(expected value for x1)
        beqz    x3, fail0       # make sure x3 has value
        lla     x4, x2_val      # load address of x2_val to x4 (expected value for x2)
        beqz    x4, fail0       # make sure x4 has value
        bne     x1, x3, fail3   # 
        bne     x2, x4, fail4   # branch to fail if not equal to expected value
         
         
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

        # -----------------------------------------
        # Data section. Note starts at 0x1000, as 
        # set by DATAADDR variable in rv_asm.bat.
        # -----------------------------------------
        .data

        # Data section
data:
        
