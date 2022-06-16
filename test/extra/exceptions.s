#
# TEST CODE FOR EXCEPTIONS (MISALIGNED LOAD, MISALIGNED STORE, EBREAK, ECALL)
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
        
        nop
        nop
        nop
        nop
        fence
        fence
        nop
        nop
  
        
        # misaligned load address exception
        lla  x1, trap_address_1         # set x1 to trap_address
        csrw mtvec, x1                  # set mtvec to trap_address
        
        li  x2, 0x1008                  # set x2 to 0x1008 
        lw  x3, 2(x2)                   # load word from data mem address 0x100a to x3 (misaligned load address)
        j   fail1                       # go to fail if no exception is raised     
        
trap_address_1:
        fence
        nop
        csrr x4, mcause                 # set x4 to mcause value 
        csrr x7, mtval                  # set x7 to mtval (address of misaligned address)
        li  x5, 0x00000004              # set x5 to 0x00000004 (expected mcause value for load addr misaligned)
        li x8, 0x100a                   # set x8 to 0x100a  (value of mtval or the misaligned address)
        beqz x5, fail0                  # make sure x5 has value
        beqz x8, fail0                  # make sure x5 has value
        bne x4, x5, fail2               # go to fail if mcause is wrong
        bne x7, x8, fail9               # go to fail if mtval is wrong
        
   
        # misaligned store address exception
        li x6, 0                        # set x6 to 0 (counter)
        lla  x1, trap_address_2         # set x1 to trap_address
        csrw mtvec, x1                  # set mtvec to trap_address
        
        fence
        sh x1, 1(x2)                    # store halfword from x1 to data mem address 0x1009 (misaligned store address)
        j fail3                         # go to fail if no exception is raised
        
trap_address_2:
        fence
        nop
        csrr x4, mcause                 # set x4 to mcause value 
        csrr x7, mtval                  # set x7 to mtval (address of misaligned address)
        li  x5, 0x00000006              # set x5 to 0x00000006 (expected mcause value for store addr misaligned)
        li x8, 0x1009                   # set x8 to 0x100a  (value of mtval or the misaligned address)
        beqz x5, fail0                  # make sure x5 has value
        beqz x8, fail0                  # make sure x5 has value
        bne x4, x5, fail4               # go to fail if mcause is wrong      
        bne x7, x8, fail9               # go to fail if mtval is wrong
        
        addi x6, x6, 1                  # increment x6
        beq x6, x5, escape_loop         # escape from loop when x6 reaches 6 
        mret                            # test mret
        
        
escape_loop:        
        # ebreak exception
        lla  x1, trap_address_3         # set x1 to trap_address
        csrw mtvec, x1                  # set mtvec to trap_address
        nop
        fence
        nop
        fence
 
        ebreak
        j fail5                         # go to fail if no exception raised
        
trap_address_3:        
        fence
        nop
        csrr x4, mcause                 # set x4 to mcause value 
        li  x5, 0x00000003              # set x5 to 0x0000000b (expected mcause value for ebreak)
        beqz x5, fail0                  # make sure x5 has value
        bne x4, x5, fail6               # go to fail if mcause is wrong
        
        
        #ecall exception
        lla  x1, trap_address_4         # set x1 to trap_address
        csrw mtvec, x1                  # set mtvec to trap_address
        nop
        fence
        nop
        fence
 
        ecall
        j fail7                         # go to fail if no exception raised
        
trap_address_4:        
        fence
        nop
        csrr x4, mcause                 # set x4 to mcause value 
        li  x5, 0x0000000b              # set x5 to 0x0000000b (expected mcause value for ebreak)
        beqz x5, fail0                  # make sure x5 has value
        bne x4, x5, fail8               # go to fail if mcause is wrong
        
        li  x1, 0x1000                  # set x1 to trap_address
        csrw mtvec, x1                  # set mtvec to trap_address

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
        
        fail5:
        li      a0, 10          # fail code
        li      a7, 93          # reached end of code
        ebreak
        
        fail6:
        li      a0, 12          # fail code
        li      a7, 93          # reached end of code
        ebreak
        
        fail7:
        li      a0, 14          # fail code
        li      a7, 93          # reached end of code
        ebreak
        
        fail8:
        li      a0, 16          # fail code
        li      a7, 93          # reached end of code
        ebreak
        
        fail9:
        li      a0, 18          # fail code
        li      a7, 93          # reached end of code
        ebreak
        
        
        # -----------------------------------------
        # Data section. Note starts at 0x1000, as 
        # set by DATAADDR variable in rv_asm.bat.
        # -----------------------------------------
        .data
        
        # Data section
data:

        
