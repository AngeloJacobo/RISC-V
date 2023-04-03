## About
Design implementation of the RISC-V Base 32 Integer core in Verilog HDL. This is a 5-stage pipeline processor core and supports the Zicsr (Control Status Registers) extension. This is RISC-V compliant and passed `rv32ui` (RV32 User-Mode Integer-Only) and `rv32mi` (RV32 Machine-Mode Integer-Only) [tests of RISC-V International.](https://github.com/riscv-software-src/riscv-tests) Formal verification via [SymbiYosys](https://github.com/YosysHQ/sby) is also utilized to  test the pipeline design. 

The RISC-V ISA implemented here is based on [Volume 1, Unprivileged Spec v. 20191213](https://github.com/riscv/riscv-isa-manual/releases/tag/Ratified-IMAFDQC) and [Volume 2, Privileged Spec v. 20211203.](https://github.com/riscv/riscv-isa-manual/releases/tag/Priv-v1.12) 

Inside the `rtl/` folder are the following:  
 - `rv32i_core.v` = top module for the RV32I core and contains formal verification properties
 - `rv32i_forwarding.v` = operand forwarding logic for data dependency hazards
 - `rv32i_basereg.v` = regfile controller for the 32 integer base registers 
 - `rv32i_fetch.v` =  retrieves instruction from the memory [FETCH STAGE]
 - `rv32i_decoder.v`= decodes the 32 bit instruction [DECODE STAGE]
 - `rv32i_alu.v` =  execute arithmetic operations and determines next `PC` and `rd` values [EXECUTE STAGE]
 - `rv32i_memoryaccess.v` = sends and retrieves data to and from the memory [MEMORYACCESS STAGE]
 - `rv32i_csr.v` = Zicsr extension module [executes parallel to MEMORYACCESS STAGE]
 - `rv32i_writeback.v` = writes `rd` to basereg and handles pipeline flushes due to traps [WRITEBACK STAGE]
 - `rv32i_header.vh` = header file which contains all necessary constants, magic numbers, and parameters
 
 Inside the `test/` folder are the following: 
 - `test.sh` = bash script for automating regression tests, program compilation, and design installation to FPGA board
 - `entry.s` = start-up assembly code used by C programs
 - `rv32i_linkerscript.ld` = script used by linker for partitioning memory sections
 - `rv32i_core.sby` = SymbiYosys script for formal verification
 - `rv32i_soc_TB.v` = testbench for `rv32i_soc`
 - `rv32i_soc.v` = complete package containing the rv32i core, RAM, IO peripherals (CLINT, I2C, UART, and GPIO), and the memory wrapper.
 - `wave.do` = Modelsim waveform template file
 - `wave.gtkw` = GTKWave waveform template file
 - `extra/` folder = contains my own assembly testfiles for all basic instructions, system instructions, and pipeline hazards
 
## Top Level Diagram (5-stage Pipeline)

## Top Level Diagram (Memory-mapped Peripherals)

## Pipeline Features
 - 5 pipelined stages  
 - Separate data and instruction memory interface **[Harvard architecture]**  
 - Load instructions take a minimum of 2 clk cycles   
 - Taken branch and jump instructions take a minimum of 3 clk cycles **[No Branch Prediction Used]**  
 - An instruction with data dependency to the next instruction that is a CSR write or Load instruction will take a minimum of 2 clk cycles **[Operand Forwarding used]**   
 - **All remaining instructions take a minimum of 1 clk cycle**   

## Supported Features of Zicsr Extension Module
 - **CSR instructions**: `CSRRW`, `CSRRS`, `CSRRC`, `CSRRWI`, `CSRRSI`, `CSRRCI`
 - **Interrupts**: `External Interrupt`, `Timer Interrupt`, `Software Interrupt`
 - **Exceptions**: `Illegal Instruction`, `Instruction Address Misaligned`, `Ecall`, `Ebreak`, `Load/Store Address Misaligned`
 - **All relevant machine level CSRs**



## Regression Tests
The RISCV toolchain `riscv64-unknown-elf-` and Modelsim executables `vsim` and `vlog` must be callable from PATH. If Modelsim executables are missing, the script will then call Icarus Verilog executables `iverilog` and `vvp` instead. Run **regression tests** inside `test/` directory either with:
 - `$ ./test.sh` = run regression tests for both `riscv-tests/isa/rv32ui/` and `riscv-tests/isa/rv32mi/`
 - `$ ./test.sh rv32ui` = run regression tests only for the `riscv-tests/isa/rv32ui/`
 - `$ ./test.sh rv32mi` = run regression tests only for the `riscv-tests/isa/rv32mi/`
 - `$ ./test.sh extra` =  run regression tests for `extra/` (contains tests for interrupts and pipeline hazards which the official tests don't have)
 - `$ ./test.sh all` = run regression tests for `riscv-tests/isa/rv32ui/`, `riscv-tests/isa/rv32mi/`, and `extra/`  
 - `$ ./test.sh formal` = run SymbiYosys formal verification tool 
 
 Some commmands for **debugging the design**:
 - `$ ./test.sh compile` = compile-only the rtl files
 - `$ ./test.sh <testfile>` = test and debug testfile <testfile> which is located at `INDIVIDUAL_TESTDIR` macro of `test.sh` script
 - `$ ./test.sh <testfile> -gui` = test and debug testfile <testfile> and open wave in Modelsim or GTKWake

Below is the expected output after running `$ ./test.sh`:   

![script](https://user-images.githubusercontent.com/87559347/177756950-deb237cf-000b-4cf2-97c4-91f3eda8c664.png)


## Goal Checklist
 :white_check_mark: Automate the testbench   
 :white_check_mark: Add Zicsr extension   
 :white_check_mark: Pass the Official RISC-V International Tests   
 :white_check_mark: Convert FSM based core implementation to pipeline   
 :white_check_mark: Add formal verification  
 :black_square_button: Add AXI interface  
 
# [UNDER CONSTRUCTION] 
