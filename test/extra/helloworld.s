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
        .equ UART_TX_DATA_ADDR, 8140
        .equ UART_TX_BUSY_ADDR, 8144
        
        ### TEST CODE STARTS HERE ###
        la      x1, data                # set x1 to address of data (0x00001000)
        li      x2, UART_TX_DATA_ADDR   # set x2 to address of UART_TX_DATA_ADDR 
        li      x3, UART_TX_BUSY_ADDR   # set x3 to address of UART_TX_BUSY_ADDR 
        
        ready:
        lb      x4, 0(x3)                   # load TX_BUSY
        bnez     x4, ready                   # branch if UART is busy
        
        print_char:
        lbu     x5, 0(x1)       # load the character stored in data to x5
        sb      x5, 0(x2)       # store character from x5 to x2 (UART_TX_DATA_ADDR)
        beqz     x5, exit        # branch to exit if character is 0
        addi    x1, x1, 1       # increment x1 (address of data) by 1
        j       ready            # jump to label ready
        
        
        ###    END OF TEST CODE   ###

        # Exit test using RISC-V International's riscv-tests pass/fail criteria
        exit:
        j   main
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
        

