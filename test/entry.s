.section .text
.global _start

_start:

     # Start-up sequence:
     # 1. Initialize all base registers to zero
     # 2. Set-up stack and global pointer. The stack pointer is loaded with the highest ram address (defined by the linker as __stack_pointer).
     # 3. Set-up the trap and exception vector (MTVEC).
     # 4. Clear the .bss section to zero. It uses the symbols __bss_start and __bss_end (defined by linker) to obtain the address range that should be set to zero. 
     # 5. (NOT NEEDED)Initialize the .data section. This section is defined in the linker script with different VMA (Virtual address) and LMA (Load address) since  
        # it has to be loaded to Flash, but used from RAM when the execution starts. To make sure that all C code can use the initialized data within the .data section, 
        # it has to be copied over from Flash to RAM by the startup code.
     # 6. Set-up call to main function
     # 7. Set-up exit routine
           
     # Initialize base registers to zero
        li  x0, 0       
        li  x1, 0       
        li  x2, 0       
        li  x3, 0       
        li  x4, 0        
        li  x5, 0       
        li  x6, 0       
        li  x7, 0       
        li  x8, 0       
        li  x9, 0       
        li  x10, 0       
        li  x11, 0        
        li  x12, 0       
        li  x13, 0       
        li  x14, 0
        li  x15, 0       
        li  x16, 0       
        li  x17, 0       
        li  x18, 0        
        li  x19, 0       
        li  x20, 0       
        li  x21, 0
        li  x22, 0       
        li  x23, 0       
        li  x24, 0       
        li  x25, 0        
        li  x26, 0       
        li  x27, 0       
        li  x28, 0
        li  x29, 0        
        li  x30, 0       
        li  x31, 0       
        
    # Set-up stack pointer
        la sp, __stack_pointer

    # Set-up global pointer
        la gp, __global_pointer$
        
    # Set-up trap vector
        csrw mtvec, zero
        csrw mie, zero
        csrw mstatus, zero
        csrw mip, zero
    
    # Clear BSS section
      la   x14,  __bss_start
      la   x15,  __bss_end

      clear_bss_loop: # store zero starting from __bss_start(included) to __bss_end(excluded)
          bge  x14,  x15, clear_bss_end
          sw   zero, 0(x14)
          addi x14,  x14, 4
          j    clear_bss_loop
      clear_bss_end:
 
    # Call main function
        jal main

    # Exit program (RISC-V test pass code)
        li    a0, 0         # set a0 (x10) to 0 to indicate a pass code
        li    a7, 93        # set a7 (x17) to 93 (5dh) to indicate reached the end of the test
        ebreak
        
        
        
    /*
    Stack pointer (SP) is a pointer that points to the top of the stack in a program's memory. 
    The stack is a region of memory used for storing local variables, function call frames, and 
    other temporary data. The stack grows downwards, which means that the stack pointer points to 
    the last used memory location on the stack. As new items are added to the stack, the stack 
    pointer is decremented to point to the new top of the stack.

    On the other hand, a global pointer (GP) is a pointer that points to a region of memory containing 
    global variables. Global variables are variables that are accessible from anywhere in the program. 
    The global pointer is usually set to point to the start of the global variable region (BSS section),
    and it remains fixed throughout the execution of the program.
    */

        
