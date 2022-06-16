#
# TEST CODE FOR SH
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
        
        # store halfword with zero immediate
        li      x1, 0x12345678  # set x1 to 0x12345678 
        li      x2, 0x1008      # set x2 to 0x1008
        sh      x1, 0(x2)       # store halfword from x1 (0x12345678) to 0x1008, mem_hw(0x1008)=0x5678 
        
        # store halfword with positive immediate
        li      x3, 0xAABBCCDD  # set x3 to 0xAABBCCDD
        sh      x3, 2(x2)       # store halfword from x3 (0xAABBCCDD) to 0x100a, mem_hw(0x100a)=0xCCDD
        
        #store halfword with negative immediate
        sh      x3, -4(x2)      # store halfword from x3(0xAABBCCDD) to 0x1004, mem_hw(0x1004)=0xCCDD
         
        # self-check 
        li      x4, 0x5678      # set x4 to 0x5678 (expected value for mem_hw(0x1008)
        beqz    x4, fail0       # make sure x4 has value
        li      x5, 0xCCDD      # set x5 to 0xCCDD (expected value for mem_hw(0x100a) and mem_hw(0x1004) )
        beqz    x5, fail0       # make sure x5 has value
        lhu     x6, 0(x2)       # load halfword from address 0x1008 to x6 (0x5678)
        lhu     x7, 2(x2)       # load halfword from address 0x100a to x7 (0xCCDD)
        lhu     x8, -4(x2)      # load halfword from address 0x1004 to x8 (0xCCDD)
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
        
