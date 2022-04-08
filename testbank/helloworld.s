#
# Display String via UART TX model of ISS
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
        la      x1, data        # set x1 to address of data (0x00001000)
        li      x2, 0x80000000  # set x2 to address of UART TX (0x80000000)
        
        loop:
        lbu     x3, 0(x1)       # load the character stored in x1(0x1000+increment) to x3
        sb      x3, 0(x2)       # store character from x3 to x2 (UART TX)
        beq     x3, x0, exit    # branch to exit if character is 0
        addi    x1, x1, 1       # increment x1 (address of data) by 1
        j       loop            # jump to label loop
        
        
        ###    END OF TEST CODE   ###

        # Exit test using RISC-V International's riscv-tests pass/fail criteria
        exit:
        li    a0, 0         # set a0 (x10) to 0 to indicate a pass code
        li    a7, 93        # set a7 (x17) to 93 (5dh) to indicate reached the end of the test
        ebreak
        
        # -----------------------------------------
        # Data section. Note starts at 0x1000, as 
        # set by DATAADDR variable in rv_asm.bat.
        # -----------------------------------------
        .data

        # Data section
data:
        .string "Hello World!"
        

