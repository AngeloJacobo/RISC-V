# Table of Contents  
- [Project Overview](https://github.com/AngeloJacobo/RISC-V/tree/main#project-overview)
- [Top Level Diagram (Classic 5-stage Pipeline)](https://github.com/AngeloJacobo/RISC-V/tree/main#top-level-diagram-classic-5-stage-pipeline)
- [Top Level Diagram (Memory-mapped Peripherals)](https://github.com/AngeloJacobo/RISC-V/tree/main#top-level-diagram-memory-mapped-peripherals)
- [Pipeline Features](https://github.com/AngeloJacobo/RISC-V/tree/main#pipeline-features)
- [Supported Features of Zicsr Extension Module](https://github.com/AngeloJacobo/RISC-V/tree/main#supported-features-of-zicsr-extension-module)
- [Regression Tests](https://github.com/AngeloJacobo/RISC-V/tree/main#regression-tests)
- [Run Individual Tests](https://github.com/AngeloJacobo/RISC-V/tree/main#run-individual-tests)
- [Install Design to FPGA (CMOD S7 FPGA Board)](https://github.com/AngeloJacobo/RISC-V/tree/main#install-design-to-fpga-cmod-s7-fpga-board)
- [Sample Application [Smart Garden Assistant with Real-time Monitoring and Security]](https://github.com/AngeloJacobo/RISC-V/tree/main#sample-application-smart-garden-assistant-with-real-time-monitoring-and-security)
- [Performance Metrics](https://github.com/AngeloJacobo/RISC-V/tree/main#performance-metrics)
- [Paper Access](https://github.com/AngeloJacobo/RISC-V/tree/main#paper-access)

## Project Overview
This project involves the design and implementation of the RISC-V Base 32 Integer core using Verilog HDL. This work includes a 5-stage pipeline processor core, which supports the Zicsr (Control Status Registers) extension. The design is RISC-V compliant and has successfully passed the `rv32ui` (RV32 User-Mode Integer-Only) and `rv32mi` (RV32 Machine-Mode Integer-Only) [tests provided by RISC-V International](https://github.com/riscv-software-src/riscv-tests). Additionally, this includes support for [FreeRTOS](https://www.freertos.org/).

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
Below is the expected output after running `$ ./test.sh`:   

![image](https://user-images.githubusercontent.com/87559347/229745971-c1e2265b-6344-4666-b93b-8685c5e06e2a.png) 

## Install Design to FPGA (CMOD S7 FPGA Board)
 - `$ ./test.sh <design> -install` = compile and install design (located at INDIVIDUAL_TESTDIR) to FPGA board
 - `$ ./test.sh freertos -install` = compile and install FreeRTOS program to FPGA board

## Sample Application [Smart Garden Assistant with Real-time Monitoring and Security]
The application code for this project can be found in `test/freertos/freertos.c`. The schematic is presented below along with the mobile app to access the device via Bluetooth. This mobile app was developed using [MIT App Inventor](https://appinventor.mit.edu/). The `apk` file is located at `test/freertos/mobile_app.apk` and the `aia` file, which can be imported to MIT App Inventor for further customization, is at `test/freertos/mobile_app.aia`.  
![image](https://github.com/AngeloJacobo/RISC-V/assets/87559347/f3ccf912-d768-4635-a7ee-a862aa411870)
 Below is the video demonstration for the sample application:  
 
[![optimized_1685749569](https://github-production-user-asset-6210df.s3.amazonaws.com/87559347/243013492-b374190a-c51d-465e-a8f4-98bc5a34159f.png)](https://youtu.be/azBM6czbunY)


## Performance Metrics 
The whole design (core + zicsr + memory-mapped peripherals + 16KB memory) is implemented on an Arty S7 FPGA board. The following metrics were collected:  
- Maximum operating frequency: 90MHz  
- Resource Utilization: 1780 LUT, 1346 FF   
- Total Power: 0.106W  

![image](https://user-images.githubusercontent.com/87559347/229773269-1f06e104-c436-4aee-9ab1-b7cb840e866e.png)

## Paper Access
The title of the paper is `Design, Implementation, and Verification of a 32-bit RISC-V Processor with Real-Time Operating System and Regression Testing Framework`. As of this moment, the paper remains unpublished so I have refrained on linking it in this public repository. But I will post it here as soon as it is published (hopefully). But if you are still interested to have a look at the paper, you can chat me via [my LinkedIn](https://www.linkedin.com/in/angelo-jacobo/) so we can discuss it. Below is the abstract of the paper:   

> RISC-V, an open standard Instruction Set Architecture (ISA), is gaining traction in various industries recently due to its open nature, straightforward design, modularity, and scalability. This paper presents the design, implementation, and verification of a 32-bit RISC-V processor with Real-Time Operating System (RTOS) support and a regression testing framework. The RISC-V core is designed using Verilog Hardware Description Language (HDL) based on the classic five-stage pipeline architecture. A comprehensive regression test is then conducted to ensure the processor core's compliance with the RISC-V ISA specifications. Thereafter, FreeRTOS is then integrated into the core, enabling effective management of time-sensitive microcontroller applications and multitasking, proving its relevance in the Internet of Things (IoT) domain. Top-level peripherals and a custom software library are also integrated to enhance the core's versatility and user-friendliness. A real-world application, the "Smart Garden Assistant with Real-time Monitoring and Security," is then developed to demonstrate the functioning RISC-V core with RTOS capability. Finally, a design evaluation is conducted and a comparative analysis is then performed to assess the design implementation against previous studies. This study aims to contribute to the growing body of research on RISC-V processors, emphasizing their value in the emerging era of open-source and customizable processor architectures.

## Goal Checklist
 :white_check_mark: Automate the testbench   
 :white_check_mark: Add Zicsr extension   
 :white_check_mark: Pass the Official RISC-V International Tests   
 :white_check_mark: Convert FSM based core implementation to pipeline   
 :white_check_mark: Add formal verification   
 :white_check_mark: Be able to run C codes  
 :white_check_mark: Add FreeRTOS Support  
 :white_check_mark: Add custom software library   
 :white_check_mark: Create a sample application using the core  
 :black_square_button: Add AXI interface     

# Donate   
Support these open-source projects by donating  

[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/donate?hosted_button_id=GBJQGJNCJZVRU)

# Inquiries  
Connect with me on LinkedIn: https://www.linkedin.com/in/angelo-jacobo/
