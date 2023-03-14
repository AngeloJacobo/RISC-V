#
# TEST CODE FOR LUI
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
        
        lui     x1, 0xABCDE     # load 0xABCDE to upper immediate of x1 (0xABCDE000)
        
        # self-check
        li      x2, 0           #
        addi    x2, x2, 0xAB    # 
        slli    x2, x2, 8       #
        addi    x2, x2, 0xCD    # 
        slli    x2, x2, 8       #
        addi    x2, x2, 0xE0    #
        sll     x2, x2, 8       # x2 = 0xABCDE000
        
        beqz    x2, fail0       # make sure x2 has value
        bne     x1, x2, fail1   # branch to fail if not equal to expected value         
         
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
     
        # -----------------------------------------
        # Data section. Note starts at 0x1000, as 
        # set by DATAADDR variable in rv_asm.bat.
        # -----------------------------------------
        .data

        # Data section
data:
        
