## ABOUT
Design implementation for the RISC-V Integer core in Verilog HDL. The core is FSM-based (no pipelining) and no Control Status Registers (CSR) yet.   
Inside the `rtl` folder are the following:  

 - `rv32i_soc.v` = complete package containing the rv32i_core , ROM (for instruction memory) , and RAM (for data memory]
 - `rv32i_core.v` = FSM controller for the fetch, decode, execute, memory access, and writeback process. 
 - `rv32i_basereg.v` = interface for the regfile of the 32 integer base registers 
 - `rv32i_decoder.v`= combinational logic for the decoding of a 32 bit instruction [DECODE STAGE]
 - `rv32i_alu.v` =  arithmetic logic unit [EXECUTE STAGE]
 - `rv32i_loadstore.v` = combinational logic for data memory access [MEMORY STAGE]
 - `rv32i_writeback.v` = combinational logic for determining the next `PC` and `rd` value [WRITEBACK STAGE]
 
Inside the `testbench` folder are the following:
 - `rv32i_soc_TB.v` = testbench for `rv32i_soc`
 - `rv32i_decoder_TB.v` = testbench for `rv32i_decoder` 
 - `rv32i_alu_TB.v` = testbench for `rv32i_alu`
 - `hexfile` folder = contains the `inst.hex` for the test instructions  
 
## Interface
Below is the interface for `rv32i_core`:

![interface_1](https://user-images.githubusercontent.com/87559347/156866977-aa026174-e13a-401c-9ef7-0bc02ba8a12c.png)

And here are the top level blocks for`rv32i_soc`:  

![interface_2](https://user-images.githubusercontent.com/87559347/156867346-322be64d-2f1c-4f70-9980-36776bcec9c0.png)



## Simple Testbench
The hex file `./hexfile/inst.hex` contains the test instructions.This is used to initialize the instruction memory regfile using the `readmemh` command. Below are the test instructions used. In comments are the equivalent assembly code of each hex instruction and its expected results.

```verilog
//memory address 0x1000 is initialized to 0x12345678
00c00093 //addi x1, x0, 12  (write 12 to x1)
00000193 //addi x3, x0, 0   (write 0 to x3)
000011b7 //lui x3, 0x1      (load value 0x1000 to x3)
0001a183 //lw x3, 0(x3)     (load value of memory address 0x1000 (which is 0x12345678) to x3) 
fff1c193 //xori x3, x3, -1  (write 0xedcba987 to x3)
00000213 //addi x4, x0, 0   (write 0 to x4)
00001237 //lui x4, 0x1      (load value 0x1000 to x4)
00322223 //sw x3, 4(x4)     (store value of x3(which is 0xedcba987) to memory address 0x1000+4 or 0x1004
00000513 //li x10, 0        (write 0 to x10)
05d00893 //li x17, 93       (write 93(0x5d) to x17)
```

The `./testbench/rv32i_soc_TB.v` monitors all writes to base register and data memory on the `rv32i_soc`. It displays the address accessed and its new value.
 - `[BASEREG]` code pertains to changes in base register
 - `[MEMORY]` code for changes in memory data.  
 - 
After executing all instructions, the state of the 32 base registers and memory data are displayed:
```

Start executing instructions......

Monitor All Writes to Base Register and Data Memory
[BASEREG] address:0x01   value:0x0000000c
[BASEREG] address:0x03   value:0x00000000
[BASEREG] address:0x03   value:0x00001000
[BASEREG] address:0x03   value:0x12345678
[BASEREG] address:0x03   value:0xedcba987
[BASEREG] address:0x04   value:0x00000000
[BASEREG] address:0x04   value:0x00001000
[MEMORY] address:0x1004   value:0xedcba987 [MASK:1111]
[BASEREG] address:0x0a   value:0x00000000
[BASEREG] address:0x11   value:0x0000005d

All instructions executed......

Final Register State:
0x00: 0x00000000	0x01: 0x0000000c	0x02: 0x00000000	0x03: 0xedcba987	
0x04: 0x00001000	0x05: 0x00000000	0x06: 0x00000000	0x07: 0x00000000	
0x08: 0x00000000	0x09: 0x00000000	0x10: 0x00000000	0x11: 0x00000000	
0x12: 0x00000000	0x13: 0x00000000	0x14: 0x00000000	0x15: 0x00000000	
0x16: 0x00000000	0x17: 0x0000005d	0x18: 0x00000000	0x19: 0x00000000	
0x20: 0x00000000	0x21: 0x00000000	0x22: 0x00000000	0x23: 0x00000000	
0x24: 0x00000000	0x25: 0x00000000	0x26: 0x00000000	0x27: 0x00000000	
0x28: 0x00000000	0x29: 0x00000000	0x30: 0x00000000	0x31: 0x00000000	


Final Memory State:
0x1000: 0x12345678
0x1004: 0xedcba987
0x1008: 0x00000000
0x100c: 0x00000000
0x1010: 0x00000000
0x1014: 0x00000000
0x1018: 0x00000000
```
Below is the screenshot of the waveforms for the relevant base registers and memory data accessed in this testbench:  

![wave](https://user-images.githubusercontent.com/87559347/156799580-2dc78eed-1ef1-4cf0-a64a-b182b0725628.png)  
 - `iaddr` = instruction address (PC value)  
 - `base_regfile[][]` = base register regfile  
 - `data_regfile[][]` = memory data regfile  

## Utilization [Vivado Synthesis Report for Spartan 7 XC7S25]  
```
+-------------------------+------+-------+------------+-----------+-------+  
|        Site Type        | Used | Fixed | Prohibited | Available | Util% |  
+-------------------------+------+-------+------------+-----------+-------+  
| Slice LUTs*             |  725 |     0 |          0 |     14600 |  4.97 |  
|   LUT as Logic          |  725 |     0 |          0 |     14600 |  4.97 |  
|   LUT as Memory         |    0 |     0 |          0 |      5000 |  0.00 |  
| Slice Registers         |  133 |     0 |          0 |     29200 |  0.46 |   
|   Register as Flip Flop |  101 |     0 |          0 |     29200 |  0.35 |  
|   Register as Latch     |   32 |     0 |          0 |     29200 |  0.11 |  
| F7 Muxes                |   33 |     0 |          0 |      7300 |  0.45 |  
| F8 Muxes                |    0 |     0 |          0 |      3650 |  0.00 |  
+-------------------------+------+-------+------------+-----------+-------+  
```

## FUTURE EXPANSIONS
 - Add more testcases for the core testbench  
 - Convert FSM to pipeline   
 - Add CSR
 - Add RV32 extensions
 
# [UNDER CONTRUCTION]
