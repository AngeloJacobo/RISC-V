## ABOUT
Design implementation of the RISC-V Integer core in Verilog HDL. The core is currently FSM-based (no pipelining) and no Control Status Registers (CSR) yet.   
Inside the `rtl` folder are the following:  

 - `rv32i_soc.v` = complete package containing the rv32i_core , ROM (for instruction memory) , and RAM (for data memory)  
 - `rv32i_core.v` = top module for the RV32I core  
 - `rv32i_fsm.v` = FSM controller for the fetch, decode, execute, memory access, and writeback processes
 - `rv32i_basereg.v` = interface for the regfile of the 32 integer base registers 
 - `rv32i_decoder.v`= logic for the decoding of a 32 bit instruction [DECODE STAGE]
 - `rv32i_alu.v` =  arithmetic logic unit [EXECUTE STAGE]
 - `rv32i_memoryaccess.v` = logic controller for data memory access [MEMORYACCESS STAGE]
 - `rv32i_writeback.v` = logic controller for determining the next `PC` and `rd` value [WRITEBACK STAGE]
 - `rv32i_soc_TB.v` = testbench for `rv32i_soc`
 
 Other files at the top directory:
 - `test.sh` = script for automating the testbench
 - `sections.py` = python script used by `test.sh` to extract the text and data sections from the binary file output of the compiler
 - `testbank/` folder = assembly testfiles for all 37 basic instructions with RISC-V International's riscv-tests pass/fail criteria
 
## INTERFACE
Here are the top level blocks for`rv32i_soc`:  

![interface_2](https://user-images.githubusercontent.com/87559347/156867346-322be64d-2f1c-4f70-9980-36776bcec9c0.png)

## AUTOMATED TESTBENCH
The RISCV toolchain `riscv64-unknown-elf-` and Modelsim executables `vsim` and `vlog` must be callable from PATH. Run script either:
 - `$ ./test.sh` = runs all testfiles and tests if PASS or FAIL (based on RISC-V International's riscv-tests pass/fail criteria)
 - `$ ./test.sh ./testbank/testfile` = run `./testbank/testfile` in debugging mode 
 - `$ ./test.sh ./testbank/testfile -gui` = run `./testbank/testfile` in debugging mode and open waveform in Modelsim gui

Below is the expected output after running `$ ./test.sh`:   

![shelloutput](https://user-images.githubusercontent.com/87559347/163819200-64af64cf-c689-4c00-af4a-dbb18ed2f3b3.png)




## UTILIZATION [Vivado Synthesis Report]  
```
+-------------------------+------+-------+------------+-----------+-------+
|        Site Type        | Used | Fixed | Prohibited | Available | Util% |
+-------------------------+------+-------+------------+-----------+-------+
| Slice LUTs*             |  727 |     0 |          0 |     14600 |  4.98 |
|   LUT as Logic          |  727 |     0 |          0 |     14600 |  4.98 |
|   LUT as Memory         |    0 |     0 |          0 |      5000 |  0.00 |
| Slice Registers         |  270 |     0 |          0 |     29200 |  0.92 |
|   Register as Flip Flop |  270 |     0 |          0 |     29200 |  0.92 |
|   Register as Latch     |    0 |     0 |          0 |     29200 |  0.00 |
| F7 Muxes                |    0 |     0 |          0 |      7300 |  0.00 |
| F8 Muxes                |    0 |     0 |          0 |      3650 |  0.00 |
+-------------------------+------+-------+------------+-----------+-------+
* Warning! The Final LUT count, after physical optimizations and full implementation, is typically lower. Run opt_design after synthesis, if not already completed, for a more realistic count.
```

## COMING SOON
 :white_check_mark: Add more testcases for the testbench    
 :white_check_mark: Automate the testbench   
 :black_square_button: Add CSR    
 :black_square_button: Convert FSM based core implementation to pipeline     
 :black_square_button: Add RV32 extensions    
 
# [UNDER CONSTRUCTION] 
