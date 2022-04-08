#
# TEST CODE FOR JALR
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
        
        # jump register
        nop                     # no operation
        nop                     # no operation
        lla     x1, jump1       # load address of jump1 to x1, x1=jump1
        jalr    x2, 0(x1)       # jump to address stored in x1 (jump1) then store next PC to x2 , x2=x2_val
        x2_val:
        j       fail1           # jump to fail
        nop                     # no operation
        nop                     # no operation
        
        jump1: 
        nop                     # no operation
        nop                     # no operation
        jalr    x3, 24(x1)     # jump to address stored in x1 plus 24 then store next PC to x3, x3=x3_val
        x3_val:
        jal     fail2           # jump to fail
        nop                     # no operation
        nop                     # no operation
        
        jump2:
        lla     x4, x2_val      # load address of x2_val to x4(expected value for x2)
        beqz    x4, fail0       # make sure x4 has value
        lla     x5, x3_val      # load address of x3_val to x5(expected value for x3)
        beqz    x5, fail0       # make sure x5 has value
        bne     x2, x4, fail3   # 
        bne     x3, x5, fail4   # branch to fail if not equal to expected value
         
         
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
        
