## ABOUT
Design implementation of the RISC-V Integer core in Verilog HDL. The core is currently FSM-based (no pipelining) and supports the Zicsr (Control Status Registers) extension.   
Inside the `rtl` folder are the following:  

 - `rv32i_soc.v` = complete package containing the rv32i_core , ROM (for instruction memory) , and RAM (for data memory)  
 - `rv32i_core.v` = top module for the RV32I core  
 - `rv32i_fsm.v` = FSM controller for the fetch, decode, execute, memory access, and writeback processes
 - `rv32i_basereg.v` = interface for the regfile of the 32 integer base registers 
 - `rv32i_decoder.v`= logic for the decoding of a 32 bit instruction [DECODE STAGE]
 - `rv32i_alu.v` =  arithmetic logic unit [EXECUTE STAGE]
 - `rv32i_memoryaccess.v` = logic controller for data memory access [MEMORYACCESS STAGE]
 - `rv32i_writeback.v` = logic controller for determining the next `PC` and `rd` value [WRITEBACK STAGE]
 - `rv32i_csr.v` = Zicsr extension module for all relevant CSRs [executes parallel to WRITEBACK STAGE]
 - `rv32i_soc_TB.v` = testbench for `rv32i_soc`
 
 Other files at the top directory:
 - `test.sh` = script for automating the testbench
 - `sections.py` = python script used by `test.sh` to extract the text and data sections from the binary file output of the compiler
 - `testbank/` folder = assembly testfiles for all basic instructions and system instructions (CSRs, interrupts, exceptions)  with RISC-V International's riscv-tests pass/fail criteria
 
## Supported Features of Zicsr Extension Module
 - **CSR instructions**: `CSRRW`, `CSRRS`, `CSRRC`, `CSRRWI`, `CSRRSI`, `CSRRCI`
 - **Interrupts**: `External Interrupt`, `Timer Interrupt`, `Software Interrupt`
 - **Exceptions**: `Illegal Instruction`, `Instruction Address Misaligned`, `Ecall`, `Ebreak`, `Load/Store Address Misaligned`
 - **All relevant machine level CSRs**



## AUTOMATED TESTBENCH
The RISCV toolchain `riscv64-unknown-elf-` and Modelsim executables `vsim` and `vlog` must be callable from PATH. Run script either:
 - `$ ./test.sh` = runs all testfiles and tests if PASS or FAIL (based on RISC-V International's riscv-tests pass/fail criteria)
 - `$ ./test.sh ./testbank/testfile` = run `./testbank/testfile` in debugging mode 
 - `$ ./test.sh ./testbank/testfile -gui` = run `./testbank/testfile` in debugging mode and open waveform in Modelsim gui
 - `$ ./test.sh compile` = compile-only the rtl files

Below is the expected output after running `$ ./test.sh`:   

![script_out](https://user-images.githubusercontent.com/87559347/169694266-02ebc975-9d23-4f62-85b8-9414d6d15eff.png)


## COMING SOON
 :white_check_mark: Add more testcases for the testbench    
 :white_check_mark: Automate the testbench   
 :white_check_mark: Add CSR    
 :black_square_button: Convert FSM based core implementation to pipeline     
 :black_square_button: Add RV32 extensions    
 
# [UNDER CONSTRUCTION] 
