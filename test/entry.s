.section .text
.global _start

_start:
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

    # Set up stack pointer
    la sp, __stack_pointer

    # Set up heap pointer
    la gp, __global_pointer

    # Call main function
    jal main

    # Exit program (RISC-V test pass code)
    li    a0, 0         # set a0 (x10) to 0 to indicate a pass code
    li    a7, 93        # set a7 (x17) to 93 (5dh) to indicate reached the end of the test
    ebreak

