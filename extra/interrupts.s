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
        ### TEST CODE STARTS HERE ###
        
        nop
        nop
        nop
        nop
        fence
        fence
        nop
        nop
  
        
        # test external interrupt
        li x1, 0b00001000
        csrw mstatus, x1                # set MIE (Machine Interrupt Enable) in mstatus
        li x1, 0b100010001000           # 
        csrw mie, x1                    # set MEIE(Machine External Interrupt Enable),MTIE(Machine Timer Interrupt Enable), and MSIE(Machine Software Interrupt Enable) in mie 
        lla x1, Interrupt               #  
        csrw mtvec, x1                  # set mtvec (trap_address) to ExternalInterrupt
EI_loop:
        nop
        nop
        nop
        j   EI_loop                     # keep looping until an external interrupt is detected
        
Interrupt:
        #rdtime x5                       # save time to x5                       
        csrr x2, mcause                 # save mcause to x2
        li  x3, 0x8000000b              # mcause for external interrupt
        li  x4, 0x80000003              # mcause for software interrupt
        li  x5, 0x80000007              # mcause for timer interrupt
        beqz x3, fail0                  # make sure x3 has value
        beqz x4, fail0                  # make sure x4 has value
        beqz x5, fail0                  # make sure x5 has value
        beq x2, x3, ExternalInterrupt
        beq x2, x4, SoftwareInterrupt
        beq x2, x5, TimerInterrupt
        j   fail1                       # mcause is not valid
        
ExternalInterrupt:
        rdtime x6                       # must be 5 (5ms)
        mret
        
SoftwareInterrupt:
        rdtime x7                       # must be 10 (10ms)
        mret
        
TimerInterrupt:
        rdtime x8                       # must be 15 (15ms)
        
        li x9, 5                        
        li x11, 10
        li x12, 15
        bne x6, x9, fail2               # failed on external interrupt
        bne x7, x11, fail3              # failed on software interrupt
        bne x8, x12, fail4              # failed on timer interrupt
        

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
        
        
        # -----------------------------------------
        # Data section. Note starts at 0x1000, as 
        # set by DATAADDR variable in rv_asm.bat.
        # -----------------------------------------
        .data
        
        # Data section
data:

        
