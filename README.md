## About
Design implementation of the RISC-V Base 32 Integer core in Verilog HDL. This is a 5-stage pipeline processor core and supports the Zicsr (Control Status Registers) extension. This is RISC-V compliant and passed `rv32ui` (RV32 User-Mode Integer-Only) and `rv32mi` (RV32 Machine-Mode Integer-Only) [tests of RISC-V International.](https://github.com/riscv-software-src/riscv-tests) Formal verification via [SymbiYosys](https://github.com/YosysHQ/sby) is also utilized to  test the pipeline design. Includes support for [FreeRTOS](https://www.freertos.org/).  

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
 - `rv32i_soc.v` = complete package containing the rv32i core, main memory, IO peripherals (CLINT, I2C, UART, and GPIO), and the memory wrapper.
 - `wave.do` = Modelsim waveform template file
 - `wave.gtkw` = GTKWave waveform template file
 - `freertos/` folder = contains files for running FreeRTOS (`FreeRTOSConfig.h` and `freertos_risc_v_chip_specific_extensions.h`)
 - `extra/` folder = contains custom assembly testfiles for all basic instructions, system instructions, and pipeline hazards.
 - `lib/` folder = contains custom software library. The function APIs can be found on `rv32i.h`. This includes:
     - LCD 1602 driver
     - HygroPMOD (Digilent) driver
     - DS1307 Real-time Clock driver
     - CLINT (Core Logic Interrupt) interface
     - UART interface
     - I2C interface
     - GPIOs interface
     - sprintf implementation  
     
Inside the `Vivado Files/` folder are the following:
- `run_vivado.tcl` = script for running Vivado in non-project mode. Used by `test.sh` to synthesize, implement, and install the design to the FPGA board.
- `Cmod-S7-25-Master.xdc` = constraint file used by Vivado to install design to the [CMOD S7 FPGA Board](https://digilent.com/reference/programmable-logic/cmod-s7/start)

## Top Level Diagram (Classic 5-stage Pipeline)
![338910881_6488549441175863_7408166598375532727_n](https://user-images.githubusercontent.com/87559347/229502697-9e7bd8c9-cb11-44e1-9ccb-7dcd42e52f9f.png)

## Top Level Diagram (Memory-mapped Peripherals)
![338677885_186797960804225_4190069677959905489_n](https://user-images.githubusercontent.com/87559347/229550336-ae914d2f-a207-404a-8652-eda9cf90b9a6.png)

## Pipeline Features
 - 5 pipelined stages  
 - Separate data and instruction memory interface **[Harvard architecture]**  
 - Load instructions take a minimum of 3 clk cycles plus any additional memory stalls   
 - Taken branch and jump instructions take a minimum of 3 clk cycles **[No Branch Prediction Used]**  
 - An instruction with data dependency to the next instruction that is a CSR write or Load instruction will take a minimum of 2 clk cycles **[Operand Forwarding used]**   
 - **All remaining instructions take a minimum of 1 clk cycle**   

## Supported Features of Zicsr Extension Module
 - **CSR instructions**: `CSRRW`, `CSRRS`, `CSRRC`, `CSRRWI`, `CSRRSI`, `CSRRCI`
 - **Interrupts**: `External Interrupt`, `Timer Interrupt`, `Software Interrupt`
 - **Exceptions**: `Illegal Instruction`, `Instruction Address Misaligned`, `Ecall`, `Ebreak`, `Load/Store Address Misaligned`
 - **All relevant machine level CSRs**


## Regression Tests
The RISC-V toolchain `riscv64-unknown-elf-` and Modelsim executables `vsim` and `vlog` must be callable from PATH. If Modelsim executables are missing, the script will then call Icarus Verilog executables `iverilog` and `vvp` instead. Run **regression tests** inside `test/` directory either with:
 - `$ ./test.sh` = run regression tests for both `riscv-tests/isa/rv32ui/` and `riscv-tests/isa/rv32mi/`
 - `$ ./test.sh rv32ui` = run regression tests only for the `riscv-tests/isa/rv32ui/`
 - `$ ./test.sh rv32mi` = run regression tests only for the `riscv-tests/isa/rv32mi/`
 - `$ ./test.sh extra` =  run regression tests for `extra/` 
 - `$ ./test.sh all` = run regression tests for `riscv-tests/isa/rv32ui/`, `riscv-tests/isa/rv32mi/`, and `extra/`  
 - `$ ./test.sh compile` = compile-only the rtl files
 
 ## Run Individual Tests
 - `$ ./test.sh <testfile>` = test and debug testfile (without simulating) which is located at INDIVIDUAL_TESTDIR
 - `$ ./test.sh <testfile> -gui` = test and debug testfile and open wave in Icarus
 - `$ ./test.sh <testfile> -nosim` = compile and debug testfile without simulating it

## Install Design to FPGA (CMOD S7 FPGA Board)
 - `$ ./test.sh <design> -install` = compile and install design (located at INDIVIDUAL_TESTDIR) to FPGA board
 - `$ ./test.sh freertos -install` = compile and install FreeRTOS progam to FPGA board


Below is the expected output after running `$ ./test.sh`:   

![image](https://user-images.githubusercontent.com/87559347/229745971-c1e2265b-6344-4666-b93b-8685c5e06e2a.png) 

## Performance Metrics 
The whole design (core + zicsr + memory-mapped peripherals + 16KB memory) is implemented on an Arty S7 FPGA board. The following metrics were collected:  
- Maximum operating frequency: 90MHz  
- Resource Utilization: 1780 LUT, 1346 FF   
- Total Power: 0.106W  

![image](https://user-images.githubusercontent.com/87559347/229773269-1f06e104-c436-4aee-9ab1-b7cb840e866e.png)



## Goal Checklist
 :white_check_mark: Automate the testbench   
 :white_check_mark: Add Zicsr extension   
 :white_check_mark: Pass the Official RISC-V International Tests   
 :white_check_mark: Convert FSM based core implementation to pipeline   
 :white_check_mark: Add formal verification   
 :white_check_mark: Be able to run C codes  
 :white_check_mark: Add FreeRTOS Support  
 :white_check_mark: Add custom software library  
 :black_square_button: Add AXI interface    
 
# [UNDER CONSTRUCTION] 
