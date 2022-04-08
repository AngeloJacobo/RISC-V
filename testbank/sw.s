#
# TEST CODE FOR SW
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
        
        # store word with zero immediate
        li      x1, 0x12345678  # set x1 to 0x12345678 
        li      x2, 0x1008      # set x2 to 0x1008
        sw      x1, 0(x2)       # store word from x1 (0x12345678) to 0x1008, mem(0x1008)=0x12345678 
        
        # store word with positive immediate
        li      x3, 0xAABBCCDD  # set x3 to 0xAABBCCDD
        sw      x3, 4(x2)       # store word from x3 (0xAABBCCDD) to 0x100C, mem(0x100C)=0xAABBCCDD
        
        #store word with negative immediate
        sw      x3, -4(x2)      # store word from x3(0xAABBCCDD) to 0x1004, mem(0x1004)=0xAABBCCDD
          
        # self-check 
        li      x4, 0x12345678  # set x4 to 0x12345678 (expected value for mem(0x1008)
        beqz    x4, fail0       # make sure x4 has value
        li      x5, 0xAABBCCDD  # set x5 to 0xAABBCCDD (expected value for mem(0x100C) and mem(0x1004) )
        beqz    x5, fail0       # make sure x5 has value
        lw      x6, 0(x2)       # load word from address 0x1008 to x6 (0x12345678)
        lw      x7, 4(x2)       # load word from address 0x100C to x7 (0xAABBCCDD)
        lw      x8, -4(x2)      # load word from address 0x1004 to x8 (0xAABBCCDD)
        bne     x6, x4, fail1   #
        bne     x7, x5, fail2   # branch to fail if not equal to expected value
        bne     x8, x5, fail3   #
        

         
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
        
