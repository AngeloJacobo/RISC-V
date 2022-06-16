#
# TEST CODE FOR BGE
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
        
        # compare positive numbers
        li      x1, 50          # set x1 to 50 (0x00000032)
        li      x2, 100         # set x2 to 100 (0x00000064)
        
        beq     x1, x0, fail0   # make sure x1 has value 
        bge     x2, x1, branch1 # if x2 >= x1, branch to branch1
        j       fail1           # jump to fail
        
        branch1: 
        bge     x1, x2, fail1   # if x1 >= x2, branch to fail
        
        # compare signed numbers
        li      x3, -50         # set x3 to -50 (0xFFFFFFCE)
        bge     x3, x1, fail2   # if x3 >= x1, branch to fail
        
        # compare equal numbers
        bge     x3, x3, pass    # if x3 >= x3, branch to pass 
        j       fail3           # jump to fail
        
        
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
        
