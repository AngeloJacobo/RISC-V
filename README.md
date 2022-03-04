# ABOUT
Design implementation of the RISC-V Integer core in Verilog HDL. The core is implemented via FSM. The standard 5 prstages 

## Hierarchy  
-> rv32i_core    
   -> rv32i_basereg  
   -> rv32i_decoder  
## Testbench
The hex file `inst.hex` contains the test instructions.This hex file initializes the instruction memory regfile using the `readmemh` command. Below are the testcases used. In comments are the equivalent assembly code of each hex instruction and the expected results of each instruction.

```verilog
//memory address 0x1000 is initialized to 0x12345678
00c00093 //addi x1, x0, 12  (write 12 to x1)
00000193 //addi x3, x0, 0   (write 0 to x3)
000011b7 //lui x3, 0x1      (load value of 0x1000 to x3)
0001a183 //lw x3, 0(x3)     (load value of memory address 0x1000 (which is 0x12345678) to x3) 
fff1c193 //xori x3, x3, -1  (write 0xedcba987 to x3)
00000213 //addi x4, x0, 0   (write 0 to x4)
00001237 //lui x4, 0x1      (load value of 0x1000 to x4)
00322223 //sw x3, 4(x4)     (store value of x3(which is 0xedcba987) to memory address 0x1000+4 or 0x1004
00000513 //li x10, 0        (write 0 to x10)
05d00893 //li x17, 93       (write 93(0x5d) to x17)
```
The `rv32i_soc_TB.v` testbench monitors changes/writes to the base register and data memory. It displays the address accessed and its new value. `[BASEREG]` code pertains to changes in base register and `[MEMORY]` code for changes in memory data. After running the testbench, this would be the result:
```
Monitor All Changes/Writes to Base Reg and Data Memory
[BASEREG] address:0x01   value:0x0000000c
[BASEREG] address:0x03   value:0x00000000
[BASEREG] address:0x03   value:0x00001000
[BASEREG] address:0x03   value:0x12345678
[BASEREG] address:0x03   value:0xedcba987
[BASEREG] address:0x04   value:0x00000000
[BASEREG] address:0x04   value:0x00001000
[MEMORY] address:0x1004   value:0xedcba987
[BASEREG] address:0x0a   value:0x00000000
[BASEREG] address:0x11   value:0x0000005d
```
Below is the screenshot of the waveforms for the relevant base registers and memory data accessed in this testbench:

![wave](https://user-images.githubusercontent.com/87559347/156799580-2dc78eed-1ef1-4cf0-a64a-b182b0725628.png)
 - `iaddr` is the instruction address (PC value)
 - `base_regfile[][]` is the base register regfile
 - `data_regfile[][]` is the memory data regfile


# TO DO
 - Add more testcases for the core testbench  
 - Convert FSM to pipeline   
 - Add CSR

# [UNDER CONTRUCTION]
