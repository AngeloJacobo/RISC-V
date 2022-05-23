## About
Design implementation of the RISC-V Integer core in Verilog HDL. The core is currently FSM-based (no pipelining) and supports the Zicsr (Control Status Registers) extension. This core is RISC-V compliant and passed `rv32ui` (RV32 User-Mode Integer-Only) and `rv32mi` (RV32 Machine-Mode Integer-Only) [tests of RISC-V International.](https://github.com/riscv-software-src/riscv-tests)

Inside the `rtl` folder are the following:  

 - `rv32i_soc.v` = complete package containing the rv32i_core and memory module for the instruction and data
 - `rv32i_core.v` = top module for the RV32I core  
 - `rv32i_fsm.v` = FSM controller for the fetch, decode, execute, memory access, and writeback processes
 - `rv32i_basereg.v` = interface for the regfile of the 32 integer base registers 
 - `rv32i_decoder.v`= logic for the decoding of a 32 bit instruction [DECODE STAGE]
 - `rv32i_alu.v` =  arithmetic logic unit [EXECUTE STAGE]
 - `rv32i_memoryaccess.v` = logic controller for data memory access [MEMORYACCESS STAGE]
 - `rv32i_csr.v` = Zicsr extension module [executes parallel to MEMORYACCESS STAGE]
 - `rv32i_writeback.v` = logic controller for trap-handling and determining the next `PC` and `rd` value [WRITEBACK STAGE]
 - `rv32i_soc_TB.v` = testbench for `rv32i_soc`
 
 Other files at the top directory:
 - `test.sh` = script for automating the testbench
 - `sections.py` = python script used by `test.sh` to extract the text and data sections from the binary file output of the compiler
 - `riscv-tests/` folder = contains the RISCV International RV32I tests
 - `riscv-test-env/` folder = contains the test environment necessary for running the RISCV International RV32I tests
 - `extra/` folder = contains nonfficial assembly testfiles for all basic instructions and system instructions (CSRs, interrupts, exceptions)
 
## Supported Features of Zicsr Extension Module
 - **CSR instructions**: `CSRRW`, `CSRRS`, `CSRRC`, `CSRRWI`, `CSRRSI`, `CSRRCI`
 - **Interrupts**: `External Interrupt`, `Timer Interrupt`, `Software Interrupt`
 - **Exceptions**: `Illegal Instruction`, `Instruction Address Misaligned`, `Ecall`, `Ebreak`, `Load/Store Address Misaligned`
 - **All relevant machine level CSRs**



## Regression Tests
The RISCV toolchain `riscv64-unknown-elf-` and Modelsim executables `vsim` and `vlog` must be callable from PATH. Run **regression tests** either with:
 - `$ ./test.sh` = run regression tests for both `riscv-tests/isa/rv32ui/` and `riscv-tests/isa/rv32mi/`
 - `$ ./test.sh rv32ui` = run regression tests only for the `riscv-tests/isa/rv32ui/`
 - `$ ./test.sh rv32mi` = run regression tests only for the `riscv-tests/isa/rv32mi/`
 - `$ ./test.sh extra` =  run regression tests for `extra/` (contains tests for interrupts which the official tests don't have)
 - `$ ./test.sh all` = run regression tests for `riscv-tests/isa/rv32ui/`, `riscv-tests/isa/rv32mi/`, and `extra/`  
 
 Some commmands for **debugging the design**:
 - `$ ./test.sh compile` = compile-only the rtl files
 - `$ ./test.sh <testfile>` = test and debug testfile <testfile> which is located at `INDIVIDUAL_TESTDIR` macro of `test.sh` script
 - `$ ./test.sh <testfile> -gui` = test and debug testfile <testfile> and open wave in Modelsim

Below is the expected output after running `$ ./test.sh`:   
![script_out_2](https://user-images.githubusercontent.com/87559347/169702033-ac69dd82-9976-4895-9978-660f8c366b53.png)

## Goal Checklist
 :white_check_mark: Add more testcases for the testbench    
 :white_check_mark: Automate the testbench   
 :white_check_mark: Add Zicsr extension   
 :white_check_mark: Pass the Official RISC-V International Tests   
 :black_square_button: Convert FSM based core implementation to pipeline       
 :black_square_button: Add RV32 extensions    
 
# [UNDER CONSTRUCTION] 
