#
# TEST CODE FOR INTERRUPTS (EXTERNAL, SOFTWARE, TIMER)
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
        .equ MTIME_BASE_ADDRESS, 8004
        .equ MTIMECMP_BASE_ADDRESS, 8012
        .equ MSIP_BASE_ADDRESS, 8020
        
        ### TEST CODE STARTS HERE ###
  
        # initial interrupt configuration
        li x1, 0b00001000
        csrw mstatus, x1                # set MIE (Machine Interrupt Enable) in mstatus
        li x1, 0b100010001000           # 
        csrw mie, x1                    # set MEIE(Machine External Interrupt Enable),MTIE(Machine Timer Interrupt Enable), and MSIE(Machine Software Interrupt Enable) in mie 
        lla x1, interrupt_handler               #  
        csrw mtvec, x1                  # set mtvec (trap_address) to interrupt_handler
        
        
# Test software interrupt
        li x2, MSIP_BASE_ADDRESS
        li x3, 1                    
        sw x3, 0(x2)                    # store 1 (enable) to MSIP_BASE_ADDRESS
        
        
# Test timer interrupt
        la x1, MTIME_BASE_ADDRESS       # 
        lw x2, 0(x1)                    # load current value of mtime (in millisecs)
        addi x2, x2, 3                  # add 3 in current mtime (3 millisec) 
        la x3, MTIMECMP_BASE_ADDRESS
        sw x2, 0(x3)                    # store the compare value (plus 3 millisec in current time)
        sw x0, 4(x3)                    # load 0 to second half 
        
loop:                                   # wait until the software or timer interrupt fires (immediate)
        nop
        j loop

        
        
interrupt_handler:
        # determine cause of interrupt   
        csrr x2, mcause                 # save mcause to x2
        li  x3, 0x8000000b              # mcause for external interrupt
        li  x4, 0x80000003              # mcause for software interrupt
        li  x5, 0x80000007              # mcause for timer interrupt
        beqz x3, fail0                  # make sure x3 has value
        beqz x4, fail0                  # make sure x4 has value
        beqz x5, fail0                  # make sure x5 has value
        beq x2, x4, check_software_interrupt # cause if software interrupt
        beq x2, x5, check_timer_interrupt    # cause is timer interrupt
        mret
        


check_software_interrupt:
        # disable software interrrupt
        li x2, MSIP_BASE_ADDRESS                 
        sw x0, 0(x2)                    # store 0 (disable) to MSIP_BASE_ADDRESS
        li x10, 1                       # save 1 to x10 after software interrupt 
        mret
        
check_timer_interrupt:
        # disable timer interrupt by resetting mtimecmp
        li x2, -1                       
        la x3, MTIMECMP_BASE_ADDRESS
        sw x2, 0(x3)                    # set MTIMECMP_BASE_ADDRESS to all 1s
        li x11, 1                       # save 1 to x11 after timer interrupt     
        
        li x15, 1
        bne x10, x15, fail0             # software interrupt did not fired
        bne x11, x15, fail1             # timer interrupt did not fired
        
        
        
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

        
