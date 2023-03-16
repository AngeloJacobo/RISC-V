/* Linker script for a RISC-V Core 32-bit integer with separate RAM and ROM */

/* Define the start address of the program */
ENTRY(_start)

/* Define the memory regions */
MEMORY
{
  /* Define the ROM(read, executable) memory region for the program */
  ROM (rx) : ORIGIN = 0, LENGTH = 4096

  /* Define the RAM(read,write,executable) memory region for the program */
  RAM (rwx) : ORIGIN = 4096, LENGTH = 8000 - 4096 /* address 8000-8192 is allotted for I/O peripherals (UART, I2C) 
  /* Thus total memory region of 8K*/
}

/* Define the sections */
SECTIONS
{
  /* Define the .text section for the program code */
  .text : ALIGN(4)
  {
    /* Include the compiled program code */
    *(.text)
  } > ROM 
    /*Save to ROM*/

  /* Define the .rodata section for read-only data */
  .rodata : ALIGN(4)
  {
    /* Include the read-only data, these are constant data that will not be modified during run-time */
    *(.rodata)
  } > ROM
    /*Save to ROM*/

  /* Define the .data section for initialized data */
  .data : ALIGN(4)
  {
    /* Include the initialized data that might be modified during run-time */
    *(.data)
  } > RAM
    /*Save to RAM*/

  /* Define the .bss section for uninitialized data */
  .bss : ALIGN(4)
  {
      /*Global pointer points to global variables which is on BSS section*/
    __global_pointer = .;
    /* Reserve space for the uninitialized data that might be modified during run-time,initially set to zero */
    *(.bss)
  } > RAM
    /*Save to RAM*/



 /* Define symbols for start and end of each memory region */
  __ram_start = ORIGIN(RAM);
  __ram_end = __ram_start + LENGTH(RAM);
  __rom_start = ORIGIN(ROM);
  __rom_end = __rom_start + LENGTH(ROM);

  /* Define the stack section */
  __stack_size = LENGTH(RAM)/4; /* 25% of total RAM will be allotted to stack */
  __stack_pointer = __ram_end - 4; 

  .stack __stack_pointer - __stack_size: ALIGN(4)
  {
    /* Reserve space for the stack */
    . += __stack_size;
  } > RAM

}

