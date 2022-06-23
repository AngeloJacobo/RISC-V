## About
Design implementation of the RISC-V Base 32 Integer core in Verilog HDL. This is a 5-stage pipeline processor core and supports the Zicsr (Control Status Registers) extension. This is RISC-V compliant and passed `rv32ui` (RV32 User-Mode Integer-Only) and `rv32mi` (RV32 Machine-Mode Integer-Only) [tests of RISC-V International.](https://github.com/riscv-software-src/riscv-tests)

Inside the `rtl/` folder are the following:  
 - `rv32i_soc.v` = complete package containing the rv32i_core and memory module for the instructions and data
 - `rv32i_core.v` = top module for the RV32I core  
 - `rv32i_basereg.v` = regfile controller for the 32 integer base registers 
 - `rv32i_fetch.v` =  retrieves instruction from the memory [FETCH STAGE]
 - `rv32i_decoder.v`= decodes the 32 bit instruction [DECODE STAGE]
 - `rv32i_alu.v` =  arithmetic logic unit [EXECUTE STAGE]
 - `rv32i_memoryaccess.v` = sends and retrieves data to and from the memory [MEMORYACCESS STAGE]
 - `rv32i_csr.v` = Zicsr extension module [executes parallel to MEMORYACCESS STAGE]
 - `rv32i_writeback.v` = handles traps and determines the next `PC` and `rd` values [WRITEBACK STAGE]
 
 Inside the `test/` folder are the following: 
 - `test.sh` = bash script for automating the testbench
 - `sections.py` = python script used by `test.sh` to extract the text and data sections from the binary file output of the compiler
 - `rv32i_soc_TB.v` = testbench for `rv32i_soc`
 - `wave.do` = Modelsim waveform file
 - `extra/` folder = contains my own assembly testfiles for all basic instructions, system instructions, and pipeline hazards
 
## Pipeline Features
 - 5 pipeline stages  
 - Separate data and instruction memory interface [Harvard architecture]  
 - Load instructions take a minimum of 2 clk cycles   
 - Taken branch and jump instructions take a minimum of 6 clk cycles [No Branch Prediction Used]  
 - Two **consecutive** instructions with data dependency take a minimum of 2 clk cycles. Nonconsecutive instructions with data dependency take a minimum of 1 clk cycle [Operation Forwarding used]   
 - All remaining instructions take a minimum of 1 clk cycle   

## Supported Features of Zicsr Extension Module
 - **CSR instructions**: `CSRRW`, `CSRRS`, `CSRRC`, `CSRRWI`, `CSRRSI`, `CSRRCI`
 - **Interrupts**: `External Interrupt`, `Timer Interrupt`, `Software Interrupt`
 - **Exceptions**: `Illegal Instruction`, `Instruction Address Misaligned`, `Ecall`, `Ebreak`, `Load/Store Address Misaligned`
 - **All relevant machine level CSRs**



## Regression Tests
The RISCV toolchain `riscv64-unknown-elf-` and Modelsim executables `vsim` and `vlog` must be callable from PATH. Run **regression tests** inside `test/` directory either with:
 - `$ ./test.sh` = run regression tests for both `riscv-tests/isa/rv32ui/` and `riscv-tests/isa/rv32mi/`
 - `$ ./test.sh rv32ui` = run regression tests only for the `riscv-tests/isa/rv32ui/`
 - `$ ./test.sh rv32mi` = run regression tests only for the `riscv-tests/isa/rv32mi/`
 - `$ ./test.sh extra` =  run regression tests for `extra/` (contains tests for interrupts and pipeline hazards which the official tests don't have)
 - `$ ./test.sh all` = run regression tests for `riscv-tests/isa/rv32ui/`, `riscv-tests/isa/rv32mi/`, and `extra/`  
 
 Some commmands for **debugging the design**:
 - `$ ./test.sh compile` = compile-only the rtl files
 - `$ ./test.sh <testfile>` = test and debug testfile <testfile> which is located at `INDIVIDUAL_TESTDIR` macro of `test.sh` script
 - `$ ./test.sh <testfile> -gui` = test and debug testfile <testfile> and open wave in Modelsim

Below is the expected output after running `$ ./test.sh`:   
 
![script_updated](https://user-images.githubusercontent.com/87559347/175277402-d0fbb6ba-53c4-4457-8730-0ce0b3c58a43.png)  
 

## Goal Checklist
 :white_check_mark: Add more testcases for the testbench    
 :white_check_mark: Automate the testbench   
 :white_check_mark: Add Zicsr extension   
 :white_check_mark: Pass the Official RISC-V International Tests   
 :white_check_mark: Convert FSM based core implementation to pipeline     
 :black_square_button: Add AXI interface  
 
# [UNDER CONSTRUCTION] 
