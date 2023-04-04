/* This is sourced from: https://github.com/stnolting/neorv32/blob/main/sw/common/neorv32.ld */

ENTRY(_start)

/* Define the memory regions */
MEMORY
{
  /* Define the ROM(read, executable) memory region for the program */
  ROM (rx) : ORIGIN = 0, LENGTH = 64k

  /* Define the RAM(read,write,executable) memory region for the program */
  RAM (rwx) : ORIGIN = 64k, LENGTH = 16k 
}


SECTIONS
{
  /* start section on WORD boundary */
  . = ALIGN(4);

  /* Actual instructions */
  .text :
  {
    PROVIDE(__text_start = .);
    PROVIDE(__textstart = .);

    PROVIDE_HIDDEN (__rela_iplt_start = .);
    *(.rela.iplt)
    PROVIDE_HIDDEN (__rela_iplt_end = .);

    *(.rela.plt)

    KEEP(*(.text.boot)); /* keep start-up code at the beginning of rom */

    KEEP (*(SORT_NONE(.init)))

    *(.text.unlikely .text.*_unlikely .text.unlikely.*)
    *(.text.exit .text.exit.*)
    *(.text.startup .text.startup.*)
    *(.text.hot .text.hot.*)
    *(SORT(.text.sorted.*))
    *(.text .stub .text.* .gnu.linkonce.t.*)
    /* .gnu.warning sections are handled specially by elf.em.  */
    *(.gnu.warning)

    KEEP (*(SORT_NONE(.fini)))

    /* We don't want to include the .ctor section from
       the crtend.o file until after the sorted ctors.
       The .ctor section from the crtend file contains the
       end of ctors marker and it must be last */
    KEEP (*(EXCLUDE_FILE (*crtend.o *crtend?.o ) .ctors))
    KEEP (*(SORT(.ctors.*)))
    KEEP (*(.ctors))

    KEEP (*crtbegin.o(.dtors))
    KEEP (*crtbegin?.o(.dtors))
    KEEP (*(EXCLUDE_FILE (*crtend.o *crtend?.o ) .dtors))
    KEEP (*(SORT(.dtors.*)))
    KEEP (*(.dtors))

    /* finish section on WORD boundary */
    . = ALIGN(4);

    PROVIDE (__etext = .);
    PROVIDE (_etext = .);
    PROVIDE (etext = .);
  } > ROM


  /* read-only data, appended to .text */
  .rodata :
  {
    PROVIDE_HIDDEN (__init_array_start = .);
    KEEP (*(SORT_BY_INIT_PRIORITY(.init_array.*) SORT_BY_INIT_PRIORITY(.ctors.*)))
    KEEP (*(.init_array EXCLUDE_FILE (*crtbegin.o *crtbegin?.o *crtend.o *crtend?.o ) .ctors))
    PROVIDE_HIDDEN (__init_array_end = .);

    PROVIDE_HIDDEN (__fini_array_start = .);
    KEEP (*(SORT_BY_INIT_PRIORITY(.fini_array.*) SORT_BY_INIT_PRIORITY(.dtors.*)))
    KEEP (*(.fini_array EXCLUDE_FILE (*crtbegin.o *crtbegin?.o *crtend.o *crtend?.o ) .dtors))
    PROVIDE_HIDDEN (__fini_array_end = .);

    *(.rodata .rodata.* .gnu.linkonce.r.*)
    *(.rodata1)

    /* finish section on WORD boundary */
    . = ALIGN(4);
  } > ROM


  /* initialized read/write data, accessed in RAM, placed in ROM, copied during boot */
  .data :
  {
    __DATA_BEGIN__ = .;
    __SDATA_BEGIN__ = .;
    *(.sdata2 .sdata2.* .gnu.linkonce.s2.*)
    *(.data1)
    *(.data .data.* .gnu.linkonce.d.*)
    SORT(CONSTRUCTORS)

    *(.data.rel.ro.local* .gnu.linkonce.d.rel.ro.local.*) *(.data.rel.ro .data.rel.ro.* .gnu.linkonce.d.rel.ro.*)
    *(.dynamic)

    /* We want the small data sections together, so single-instruction offsets
       can access them all, and initialized data all before uninitialized, so
       we can shorten the on-disk segment size.  */

    *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2) *(.srodata .srodata.*)
    *(.sdata .sdata.* .gnu.linkonce.s.*)

     PROVIDE_HIDDEN (__tdata_start = .);
     *(.tdata .tdata.* .gnu.linkonce.td.*)


    /* finish section on WORD boundary */
    . = ALIGN(4);

    _edata = .; PROVIDE (edata = .);
    . = .;

  } > RAM


  /* zero/non-initialized read/write data placed in RAM */
  .bss (NOLOAD):
  {
    __bss_start = .;
    *(.dynsbss)
    *(.sbss .sbss.* .gnu.linkonce.sb.*)
    *(.sbss2 .sbss2.* .gnu.linkonce.sb2.*)
    *(.tbss .tbss.* .gnu.linkonce.tb.*) *(.tcommon)
    *(.scommon)
    *(.dynbss)
    *(.bss .bss.* .gnu.linkonce.b.*)

    PROVIDE_HIDDEN (__preinit_array_start = .);
    KEEP (*(.preinit_array))
    PROVIDE_HIDDEN (__preinit_array_end = .);

    *(COMMON)
    /* Align here to ensure that the .bss section occupies space up to
       _end.  Align after .bss to ensure correct alignment even if the
       .bss section disappears because there are no input sections.
       FIXME: Why do we need it? When there is no .bss section, we do not
       pad the .data section.  */
    . = ALIGN(. != 0 ? 32 / 8 : 1);

    . = ALIGN(32 / 8);
    __bss_end = .;
    __global_pointer$ = MIN(__SDATA_BEGIN__ + 0x800, MAX(__DATA_BEGIN__ + 0x800, __bss_end - 0x800));
    _end = .; PROVIDE (end = .);
  } > RAM
  



 /* Define symbols for start and end of each memory region */
  __ram_start = ORIGIN(RAM);
  __ram_end = __ram_start + LENGTH(RAM);
  __rom_start = ORIGIN(ROM);
  __rom_end = __rom_start + LENGTH(ROM);

  /* Define the stack section */
  __stack_pointer = __ram_end - 4; 



}
