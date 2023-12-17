// Core plus memory

`timescale 1ns / 1ps
`default_nettype none
//`define ICARUS use faster UARt and I2C rate for faster simulation

//complete package containing the rv32i_core, RAM, and IO peripherals (I2C and UART)
module rv32i_soc #(parameter CLK_FREQ_MHZ=12, PC_RESET=32'h00_00_00_00, TRAP_ADDRESS=32'h00_00_00_00, ZICSR_EXTENSION=1, MEMORY_DEPTH=81920, GPIO_COUNT = 12) ( 
    input wire i_clk,
    input wire i_rst,
    //UART
    input wire uart_rx,
    output wire uart_tx,
    //I2C
    inout wire i2c_sda,
    inout wire i2c_scl,
    //GPIO
    inout wire[GPIO_COUNT-1:0] gpio_pins
    );

    
    //Instruction Memory Interface
    wire[31:0] inst; 
    wire[31:0] iaddr;  
    wire i_stb_inst;
    wire o_ack_inst;
    
    //Data Memory Interface
    wire[31:0] i_wb_data_data; //data retrieved from memory
    wire[31:0] o_wb_data_data; //data to be stored to memory
    wire[31:0] wb_addr_data; //address of data memory for store/load
    wire[3:0] wb_sel_data; //byte strobe for write (1 = write the byte) {byte3,byte2,byte1,byte0}
    wire wb_we_data; //write-enable (1 = write, 0 = read) 
    wire wb_stb_data; //request for read/write access to data memory
    wire wb_ack_data; //ack by data memory (high when data to be read is ready or when write data is already written
    wire wb_cyc_data; //bus cycle active (1 = normal operation, 0 = all ongoing transaction are to be cancelled)
    wire wb_stall_data; //stall by data memory
    
    //Interrupts
    wire i_external_interrupt = 0; //interrupt from external source
    wire o_timer_interrupt; //interrupt from CLINT
    wire o_software_interrupt; //interrupt from CLINT
    
    //Memory Wrapper
    wire device0_wb_cyc;
    wire device0_wb_stb;
    wire device0_wb_we;
    wire[31:0] device0_wb_addr;
    wire[31:0] o_device0_wb_data;
    wire[3:0] device0_wb_sel;
    wire device0_wb_ack;
    wire device0_wb_stall;
    wire[31:0] i_device0_wb_data;

    wire device1_wb_cyc;
    wire device1_wb_stb;
    wire device1_wb_we;
    wire[31:0] device1_wb_addr;
    wire[31:0] o_device1_wb_data;
    wire[3:0] device1_wb_sel;
    wire device1_wb_ack;
    wire device1_wb_stall;
    wire[31:0] i_device1_wb_data;

    wire device2_wb_cyc;
    wire device2_wb_stb;
    wire device2_wb_we;
    wire[31:0] device2_wb_addr;
    wire[31:0] o_device2_wb_data;
    wire[3:0] device2_wb_sel;
    wire device2_wb_ack;
    wire device2_wb_stall;
    wire[31:0] i_device2_wb_data;

    wire device3_wb_cyc;
    wire device3_wb_stb;
    wire device3_wb_we;
    wire[31:0] device3_wb_addr;
    wire[31:0] o_device3_wb_data;
    wire[3:0] device3_wb_sel;
    wire device3_wb_ack;
    wire device3_wb_stall;
    wire[31:0] i_device3_wb_data;

    wire device4_wb_cyc;
    wire device4_wb_stb;
    wire device4_wb_we;
    wire[31:0] device4_wb_addr;
    wire[31:0] o_device4_wb_data;
    wire[3:0] device4_wb_sel;
    wire device4_wb_ack;
    wire device4_wb_stall;
    wire[31:0] i_device4_wb_data;

    wire device5_wb_cyc;
    wire device5_wb_stb;
    wire device5_wb_we;
    wire[31:0] device5_wb_addr;
    wire[31:0] o_device5_wb_data;
    wire[3:0] device5_wb_sel;
    wire device5_wb_ack;
    wire device5_wb_stall;
    wire[31:0] i_device5_wb_data;

    rv32i_core #(.PC_RESET(PC_RESET), .TRAP_ADDRESS(TRAP_ADDRESS), .ZICSR_EXTENSION(ZICSR_EXTENSION)) m0( //main RV32I core
        .i_clk(i_clk),
        .i_rst_n(!i_rst),
        //Instruction Memory Interface
        .i_inst(inst), //32-bit instruction
        .o_iaddr(iaddr), //address of instruction 
        .o_stb_inst(i_stb_inst), //request for read access to instruction memory
        .i_ack_inst(o_ack_inst),  //ack (high if new instruction is ready)
        //Data Memory Interface
        .o_wb_cyc_data(wb_cyc_data), //bus cycle active (1 = normal operation, 0 = all ongoing transaction are to be cancelled)
        .o_wb_stb_data(wb_stb_data), //request for read/write access to data memory
        .o_wb_we_data(wb_we_data), //write-enable (1 = write, 0 = read)
        .o_wb_addr_data(wb_addr_data), //address of data memory for store/load
        .o_wb_data_data(o_wb_data_data), //data to be stored to memory
        .o_wb_sel_data(wb_sel_data), //byte strobe for write (1 = write the byte) {byte3,byte2,byte1,byte0}
        .i_wb_ack_data(wb_ack_data), //ack by data memory (high when read data is ready or when write data is already written)
        .i_wb_stall_data(wb_stall_data), //stall by data memory
        .i_wb_data_data(i_wb_data_data), //data retrieved from memory
        //Interrupts
        .i_external_interrupt(i_external_interrupt), //interrupt from external source
        .i_software_interrupt(o_software_interrupt), //interrupt from software (inter-processor interrupt)
        .i_timer_interrupt(o_timer_interrupt) //interrupt from timer
     );
        
    memory_wrapper wrapper( //decodes address and access the corresponding memory-mapped device
        //RISC-V Core
        .i_wb_cyc(wb_cyc_data),
        .i_wb_stb(wb_stb_data),
        .i_wb_we(wb_we_data),
        .i_wb_addr(wb_addr_data),
        .i_wb_data(o_wb_data_data),
        .i_wb_sel(wb_sel_data),
        .o_wb_ack(wb_ack_data),
        .o_wb_stall(wb_stall_data),
        .o_wb_data(i_wb_data_data),

        //Device 0 Interface (RAM)
        .o_device0_wb_cyc(device0_wb_cyc),
        .o_device0_wb_stb(device0_wb_stb),
        .o_device0_wb_we(device0_wb_we),
        .o_device0_wb_addr(device0_wb_addr),
        .o_device0_wb_data(o_device0_wb_data),
        .o_device0_wb_sel(device0_wb_sel),
        .i_device0_wb_ack(device0_wb_ack),
        .i_device0_wb_stall(device0_wb_stall),
        .i_device0_wb_data(i_device0_wb_data),

        //Device 1 Interface (CLINT)
        .o_device1_wb_cyc(device1_wb_cyc),
        .o_device1_wb_stb(device1_wb_stb),
        .o_device1_wb_we(device1_wb_we),
        .o_device1_wb_addr(device1_wb_addr),
        .o_device1_wb_data(o_device1_wb_data),
        .o_device1_wb_sel(device1_wb_sel),
        .i_device1_wb_ack(device1_wb_ack),
        .i_device1_wb_stall(device1_wb_stall),
        .i_device1_wb_data(i_device1_wb_data),
        
        //Device 2 Interface (UART)
        .o_device2_wb_cyc(device2_wb_cyc),
        .o_device2_wb_stb(device2_wb_stb),
        .o_device2_wb_we(device2_wb_we),
        .o_device2_wb_addr(device2_wb_addr),
        .o_device2_wb_data(o_device2_wb_data),
        .o_device2_wb_sel(device2_wb_sel),
        .i_device2_wb_ack(device2_wb_ack),
        .i_device2_wb_stall(device2_wb_stall),
        .i_device2_wb_data(i_device2_wb_data),
        
        //Device 3 Interface (I2C)
        .o_device3_wb_cyc(device3_wb_cyc),
        .o_device3_wb_stb(device3_wb_stb),
        .o_device3_wb_we(device3_wb_we),
        .o_device3_wb_addr(device3_wb_addr),
        .o_device3_wb_data(o_device3_wb_data),
        .o_device3_wb_sel(device3_wb_sel),
        .i_device3_wb_ack(device3_wb_ack),
        .i_device3_wb_stall(device3_wb_stall),
        .i_device3_wb_data(i_device3_wb_data),
        
        //Device 4 Interface (GPIO)
        .o_device4_wb_cyc(device4_wb_cyc),
        .o_device4_wb_stb(device4_wb_stb),
        .o_device4_wb_we(device4_wb_we),
        .o_device4_wb_addr(device4_wb_addr),
        .o_device4_wb_data(o_device4_wb_data),
        .o_device4_wb_sel(device4_wb_sel),
        .i_device4_wb_ack(device4_wb_ack),
        .i_device4_wb_stall(device4_wb_stall),
        .i_device4_wb_data(i_device4_wb_data),

        //Device 5 Interface (DDR3)
        .o_device5_wb_cyc(device5_wb_cyc),
        .o_device5_wb_stb(device5_wb_stb),
        .o_device5_wb_we(device5_wb_we),
        .o_device5_wb_addr(device5_wb_addr),
        .o_device5_wb_data(o_device5_wb_data),
        .o_device5_wb_sel(device5_wb_sel),
        .i_device5_wb_ack(device5_wb_ack),
        .i_device5_wb_stall(device5_wb_stall),
        .i_device5_wb_data(i_device5_wb_data)
    );   

    // DEVICE 0
     main_memory #(.MEMORY_DEPTH(MEMORY_DEPTH)) m1( //Instruction and Data memory (combined memory) 
        .i_clk(i_clk),
        // Instruction Memory
        .i_inst_addr(iaddr[$clog2(MEMORY_DEPTH)-1:0]),
        .o_inst_out(inst),
        .i_stb_inst(i_stb_inst), 
        .o_ack_inst(o_ack_inst), 
        // Data Memory
        .i_wb_cyc(device0_wb_cyc),
        .i_wb_stb(device0_wb_stb),
        .i_wb_we(device0_wb_we),
        .i_wb_addr(device0_wb_addr[$clog2(MEMORY_DEPTH)-1:0]),
        .i_wb_data(o_device0_wb_data),
        .i_wb_sel(device0_wb_sel),
        .o_wb_ack(device0_wb_ack),
        .o_wb_stall(device0_wb_stall),
        .o_wb_data(i_device0_wb_data)
    );

    // DEVICE 1
    rv32i_clint #( //Core Logic Interrupt [memory-mapped to < h50 (MSB=1)]
        .CLK_FREQ_MHZ(CLK_FREQ_MHZ), //input clock frequency in MHz
        .MTIME_BASE_ADDRESS(32'h8000_0000),  //Machine-level timer register (64-bits, 2 words)
        .MTIMECMP_BASE_ADDRESS(32'h8000_0008), //Machine-level Time Compare register (64-bits, 2 words)
        .MSIP_BASE_ADDRESS(32'h8000_0010) //Machine-level Software Interrupt register
    ) clint  (
        .clk(i_clk),
        .rst_n(!i_rst),
        .i_wb_cyc(device1_wb_cyc),
        .i_wb_stb(device1_wb_stb),
        .i_wb_we(device1_wb_we),
        .i_wb_addr(device1_wb_addr),
        .i_wb_data(o_device1_wb_data),
        .i_wb_sel(device1_wb_sel),
        .o_wb_ack(device1_wb_ack),
        .o_wb_stall(device1_wb_stall),
        .o_wb_data(i_device1_wb_data),
        // Interrupts
        .o_timer_interrupt(o_timer_interrupt),
        .o_software_interrupt(o_software_interrupt)
    );

    // DEVICE 2
    uart #( .CLOCK_FREQ(CLK_FREQ_MHZ*1_000_000), //UART (TX only) [memory-mapped to >=h50,<hA0 (MSB=1)]
            .BAUD_RATE( //UART Baud rate
              `ifdef ICARUS
               2_000_000 //faster simulation            delay_count <= 5;

               `else 
               9600 //9600 Baud
               `endif),
            .UART_TX_DATA(32'h8000_0050), //memory-mapped address for TX
            .UART_TX_BUSY(32'h8000_0054), //memory-mapped address to check if TX is busy (has ongoing request)
            .UART_RX_BUFFER_FULL(32'h8000_0058), //memory-mapped address  to check if a read has completed
            .UART_RX_DATA(32'h8000_005C), //memory-mapped address for RX 
            .DBIT(8), //UART Data Bits
            .SBIT(1) //UART Stop Bits
     ) uart
     (
        .clk(i_clk),
        .rst_n(!i_rst),
        .i_wb_cyc(device2_wb_cyc),
        .i_wb_stb(device2_wb_stb),
        .i_wb_we(device2_wb_we),
        .i_wb_addr(device2_wb_addr),
        .i_wb_data(o_device2_wb_data[7:0]),
        .i_wb_sel(device2_wb_sel),
        .o_wb_ack(device2_wb_ack),
        .o_wb_stall(device2_wb_stall),
        .o_wb_data(i_device2_wb_data[7:0]),
        .uart_rx(uart_rx), //UART RX line
        .uart_tx(uart_tx) //UART TX line
      );

    // CONTINUE////////////////////////////////////////
    //DEVICE 3
    i2c #(.main_clock(CLK_FREQ_MHZ*1_000_000), //SCCB mode(no pullups resistors needed) [memory-mapped to >=A0,<F0 (MSB=1)]
          .freq( //i2c freqeuncy
          `ifdef ICARUS
           2_000_000 //faster simulation
           `else 
           100_000 //100KHz
           `endif),
          .addr_bytes(1), //addr_bytes=number of bytes of an address
          .I2C_START(32'h8000_00A0), //write-only memory-mapped address to start i2c (write the i2c slave address)
          .I2C_WRITE(32'h8000_00A4), //write-only memory-mapped address for sending data to slave
          .I2C_READ(32'h8000_00A8), //read-only memory-mapped address to read data received from slave (this will also continue reading from slave) 
          .I2C_BUSY(32'h8000_00AC), //read-only memory-mapped address to check if i2c is busy (cannot accept request)
          .I2C_ACK(32'h8000_00B0), //read-only memory-mapped address to check if last access has benn acknowledge by slave
          .I2C_READ_DATA_READY(32'h8000_00B4), //read-only memory-mapped address to check if data to be received from slave is ready
          .I2C_STOP(32'h8000_00B8) //write-only memory-mapped address to stop i2c (this is persistent thus must be manually turned off after stopping i2c)
      ) i2c
      (
        .clk(i_clk),
        .rst_n(!i_rst),
        .i_wb_cyc(device3_wb_cyc),
        .i_wb_stb(device3_wb_stb),
        .i_wb_we(device3_wb_we),
        .i_wb_addr(device3_wb_addr),
        .i_wb_data(o_device3_wb_data[7:0]),
        .i_wb_sel(device3_wb_sel),
        .o_wb_ack(device3_wb_ack),
        .o_wb_stall(device3_wb_stall),
        .o_wb_data(i_device3_wb_data[7:0]),
        .scl(i2c_scl), //i2c bidrectional clock line
        .sda(i2c_sda) //i2c bidrectional data line
    );
    
    //DEVICE 4
    gpio #( //General-Purpose Input-Ouput
        .GPIO_MODE(32'h8000_00F0), //set if GPIO will be read(0) or write(1) 
        .GPIO_READ(32'h8000_00F4), //read GPIO value
        .GPIO_WRITE(32'h8000_00F8), //write to GPIO
        .GPIO_COUNT(12)
    ) gpio (
        .clk(i_clk),
        .rst_n(!i_rst),
        .i_wb_cyc(device4_wb_cyc),
        .i_wb_stb(device4_wb_stb),
        .i_wb_we(device4_wb_we),
        .i_wb_addr(device4_wb_addr),
        .i_wb_data(o_device4_wb_data[GPIO_COUNT-1:0]),
        .i_wb_sel(device4_wb_sel),
        .o_wb_ack(device4_wb_ack),
        .o_wb_stall(device4_wb_stall),
        .o_wb_data(i_device4_wb_data[GPIO_COUNT-1:0]),
        //GPIO
        .gpio(gpio_pins) //gpio pins
    );

`ifdef DDR3
    wire clk_locked;
    wire i_controller_clk, i_ddr3_clk, i_ref_clk, i_ddr3_clk_90;

    clk_wiz_0 clk_wiz_inst
    (
    // Clock out ports
    .clk_out1(i_controller_clk), //83.33333 Mhz
    .clk_out2(i_ddr3_clk), // 333.33333 MHz
    .clk_out3(i_ref_clk), //200MHz
    .clk_out4(i_ddr3_clk_90), // 333.33333 MHz vs 90 degrees shift
    // Status and control signals
    .reset(i_rst),
    .locked(clk_locked),
    // Clock in ports
    .clk_in1(i_clk) 
    );

    //DEVICE 5 (DDR3 Controller)
    ddr3_top #(
        .CONTROLLER_CLK_PERIOD(12_000), //ps, clock period of the controller interface
        .DDR3_CLK_PERIOD(3_000), //ps, clock period of the DDR3 RAM device (must be 1/4 of the CONTROLLER_CLK_PERIOD) 
        .ROW_BITS(14), //width of row address
        .COL_BITS(10), //width of column address
        .BA_BITS(3), //width of bank address
        .DQ_BITS(8),  //device width
        .LANES(2), //number of DDR3 device to be controlled
        .AUX_WIDTH(4), //width of aux line (must be >= 4) 
        .WB2_ADDR_BITS(32), //width of 2nd wishbone address bus 
        .WB2_DATA_BITS(32), //width of 2nd wishbone data bus
        .OPT_LOWPOWER(1), //1 = low power, 0 = low logic
        .OPT_BUS_ABORT(1),  //1 = can abort bus, 0 = no absort (i_wb_cyc will be ignored, ideal for an AXI implementation which cannot abort transaction)
        .MICRON_SIM(0), //enable faster simulation for micron ddr3 model (shorten POWER_ON_RESET_HIGH and INITIAL_CKE_LOW)
        .ODELAY_SUPPORTED(0), //set to 1 when ODELAYE2 is supported
        .SECOND_WISHBONE(0) //set to 1 if 2nd wishbone is needed 
        ) ddr3_top
        (
            //clock and reset
            .i_controller_clk(i_controller_clk),
            .i_ddr3_clk(i_ddr3_clk), //i_controller_clk has period of CONTROLLER_CLK_PERIOD, i_ddr3_clk has period of DDR3_CLK_PERIOD 
            .i_ref_clk(i_ref_clk),
            .i_ddr3_clk_90(i_ddr3_clk_90),
            .i_rst_n(!i_rst && clk_locked), 
            //
            // Wishbone inputs
            .i_wb_cyc(device5_wb_cyc), //bus cycle active (1 = normal operation, 0 = all ongoing transaction are to be cancelled)
            .i_wb_stb(device5_wb_stb), //request a transfer
            .i_wb_we(device5_wb_we), //write-enable (1 = write, 0 = read)
            .i_wb_addr(device5_wb_addr), //burst-addressable {row,bank,col} 
            .i_wb_data(o_device5_wb_data), //write data, for a 4:1 controller data width is 8 times the number of pins on the device
            .i_wb_sel(device5_wb_sel), //byte strobe for write (1 = write the byte)
            .i_aux(0), //for AXI-interface compatibility (given upon strobe)
            // Wishbone outputs
            .o_wb_stall(device5_wb_stall), //1 = busy, cannot accept requests
            .o_wb_ack(device5_wb_ack), //1 = read/write request has completed
            .o_wb_data(i_device5_wb_data), //read data, for a 4:1 controller data width is 8 times the number of pins on the device
            .o_aux(),
            //
            // Wishbone 2 (PHY) inputs
            .i_wb2_cyc(), //bus cycle active (1 = normal operation, 0 = all ongoing transaction are to be cancelled)
            .i_wb2_stb(), //request a transfer
            .i_wb2_we(), //write-enable (1 = write, 0 = read)
            .i_wb2_addr(), //burst-addressable {row,bank,col} 
            .i_wb2_data(), //write data, for a 4:1 controller data width is 8 times the number of pins on the device
            .i_wb2_sel(), //byte strobe for write (1 = write the byte)
            // Wishbone 2 (Controller) outputs
            .o_wb2_stall(), //1 = busy, cannot accept requests
            .o_wb2_ack(), //1 = read/write request has completed
            .o_wb2_data(), //read data, for a 4:1 controller data width is 8 times the number of pins on the device
            //
            // DDR3 I/O Interface
            .o_ddr3_clk_p(ddr3_clk_p),
            .o_ddr3_clk_n(ddr3_clk_n),
            .o_ddr3_reset_n(ddr3_reset_n),
            .o_ddr3_cke(ddr3_cke), // CKE
            .o_ddr3_cs_n(ddr3_cs_n), // chip select signal (controls rank 1 only)
            .o_ddr3_ras_n(ddr3_ras_n), // RAS#
            .o_ddr3_cas_n(ddr3_cas_n), // CAS#
            .o_ddr3_we_n(ddr3_we_n), // WE#
            .o_ddr3_addr(ddr3_addr),
            .o_ddr3_ba_addr(ddr3_ba),
            .io_ddr3_dq(ddr3_dq),
            .io_ddr3_dqs(ddr3_dqs_p),
            .io_ddr3_dqs_n(ddr3_dqs_n),
            .o_ddr3_dm(ddr3_dm),
            .o_ddr3_odt(ddr3_odt), // on-die termination
            // Debug outputs
            .o_debug1(),
            .o_debug2(),
            .o_debug3(),
            .o_ddr3_debug_read_dqs_p(),
            .o_ddr3_debug_read_dqs_n()
            ////////////////////////////////////
        );
        
`endif

endmodule


module memory_wrapper ( //decodes address and access the corresponding memory-mapped device
    //RISC-V Core
    input wire i_wb_cyc,
    input wire i_wb_stb,
    input wire i_wb_we,
    input wire[31:0] i_wb_addr,
    input wire[31:0] i_wb_data,
    input wire[3:0] i_wb_sel,
    output reg o_wb_ack,
    output reg o_wb_stall,
    output reg[31:0] o_wb_data,

    //Device 0 Interface (RAM)
    output reg o_device0_wb_cyc,
    output reg o_device0_wb_stb,
    output reg o_device0_wb_we,
    output reg[31:0] o_device0_wb_addr,
    output reg[31:0] o_device0_wb_data,
    output reg[3:0] o_device0_wb_sel,
    input wire i_device0_wb_ack,
    input wire i_device0_wb_stall,
    input wire[31:0] i_device0_wb_data,

    //Device 1 Interface (CLINT)
    output reg o_device1_wb_cyc,
    output reg o_device1_wb_stb,
    output reg o_device1_wb_we,
    output reg[31:0] o_device1_wb_addr,
    output reg[31:0] o_device1_wb_data,
    output reg[3:0] o_device1_wb_sel,
    input wire i_device1_wb_ack,
    input wire i_device1_wb_stall,
    input wire[31:0] i_device1_wb_data,

    //Device 2 Interface (UART)
    output reg o_device2_wb_cyc,
    output reg o_device2_wb_stb,
    output reg o_device2_wb_we,
    output reg[31:0] o_device2_wb_addr,
    output reg[31:0] o_device2_wb_data,
    output reg[3:0] o_device2_wb_sel,
    input wire i_device2_wb_ack,
    input wire i_device2_wb_stall,
    input wire[31:0] i_device2_wb_data,

    //Device 3 Interface (I2C)
    output reg o_device3_wb_cyc,
    output reg o_device3_wb_stb,
    output reg o_device3_wb_we,
    output reg[31:0] o_device3_wb_addr,
    output reg[31:0] o_device3_wb_data,
    output reg[3:0] o_device3_wb_sel,
    input wire i_device3_wb_ack,
    input wire i_device3_wb_stall,
    input wire[31:0] i_device3_wb_data,
    
    //Device 4 Interface (GPIO)
    output reg o_device4_wb_cyc,
    output reg o_device4_wb_stb,
    output reg o_device4_wb_we,
    output reg[31:0] o_device4_wb_addr,
    output reg[31:0] o_device4_wb_data,
    output reg[3:0] o_device4_wb_sel,
    input wire i_device4_wb_ack,
    input wire i_device4_wb_stall,
    input wire[31:0] i_device4_wb_data,

    //Device 5 Interface (DDR3)
    output reg o_device5_wb_cyc,
    output reg o_device5_wb_stb,
    output reg o_device5_wb_we,
    output reg[31:0] o_device5_wb_addr,
    output reg[31:0] o_device5_wb_data,
    output reg[3:0] o_device5_wb_sel,
    input wire i_device5_wb_ack,
    input wire i_device5_wb_stall,
    input wire[31:0] i_device5_wb_data
);


    always @* begin 
        o_wb_ack = 0;
        o_wb_stall = 0;
        o_wb_data = 0;

        o_device0_wb_cyc = 0;
        o_device0_wb_stb = 0;
        o_device0_wb_we = 0;
        o_device0_wb_addr = 0;
        o_device0_wb_data = 0;
        o_device0_wb_sel = 0;

        o_device1_wb_cyc = 0;
        o_device1_wb_stb = 0;
        o_device1_wb_we = 0;
        o_device1_wb_addr = 0;
        o_device1_wb_data = 0;
        o_device1_wb_sel = 0;

        o_device2_wb_cyc = 0;
        o_device2_wb_stb = 0;
        o_device2_wb_we = 0;
        o_device2_wb_addr = 0;
        o_device2_wb_data = 0;
        o_device2_wb_sel = 0;

        o_device3_wb_cyc = 0;
        o_device3_wb_stb = 0;
        o_device3_wb_we = 0;
        o_device3_wb_addr = 0;
        o_device3_wb_data = 0;
        o_device3_wb_sel = 0;

        o_device4_wb_cyc = 0;
        o_device4_wb_stb = 0;
        o_device4_wb_we = 0;
        o_device4_wb_addr = 0;
        o_device4_wb_data = 0;
        o_device4_wb_sel = 0;

        o_device5_wb_cyc = 0;
        o_device5_wb_stb = 0;
        o_device5_wb_we = 0;
        o_device5_wb_addr = 0;
        o_device5_wb_data = 0;
        o_device5_wb_sel = 0;

        // Memory-mapped peripherals address has MSB set to 1
        if(i_wb_addr[31]) begin
            if(i_wb_addr[11:0] < 12'h50) begin //Device 1 Interface (CLINT) (20 words)
                o_device1_wb_cyc = i_wb_cyc;
                o_device1_wb_stb = i_wb_stb;
                o_device1_wb_we = i_wb_we;
                o_device1_wb_addr = i_wb_addr; 
                o_device1_wb_data = i_wb_data;
                o_device1_wb_sel = i_wb_sel; 
                o_wb_ack = i_device1_wb_ack;
                o_wb_stall = i_device1_wb_stall;
                o_wb_data = i_device1_wb_data;
            end
            
            if(i_wb_addr[11:0] >= 12'h50 && i_wb_addr[11:0] < 12'hA0) begin //Device 2 Interface (UART) (20 words)
                o_device2_wb_cyc = i_wb_cyc;
                o_device2_wb_stb = i_wb_stb;
                o_device2_wb_we = i_wb_we;
                o_device2_wb_addr = i_wb_addr; 
                o_device2_wb_data = i_wb_data;
                o_device2_wb_sel = i_wb_sel; 
                o_wb_ack = i_device2_wb_ack;
                o_wb_stall = i_device2_wb_stall;
                o_wb_data = i_device2_wb_data;
            end

            if(i_wb_addr[11:0] >= 12'hA0 && i_wb_addr[11:0] < 12'hF0) begin //Device 3 Interface (I2C) (20 words)
                o_device3_wb_cyc = i_wb_cyc;
                o_device3_wb_stb = i_wb_stb;
                o_device3_wb_we = i_wb_we;
                o_device3_wb_addr = i_wb_addr; 
                o_device3_wb_data = i_wb_data;
                o_device3_wb_sel = i_wb_sel; 
                o_wb_ack = i_device3_wb_ack;
                o_wb_stall = i_device3_wb_stall;
                o_wb_data = i_device3_wb_data;
            end
            
            if(i_wb_addr[11:0] >= 12'hF0 && i_wb_addr[11:0] < 12'h140) begin //Device 4 Interface (GPIO) (20 words)
                o_device4_wb_cyc = i_wb_cyc;
                o_device4_wb_stb = i_wb_stb;
                o_device4_wb_we = i_wb_we;
                o_device4_wb_addr = i_wb_addr; 
                o_device4_wb_data = i_wb_data;
                o_device4_wb_sel = i_wb_sel; 
                o_wb_ack = i_device4_wb_ack;
                o_wb_stall = i_device4_wb_stall;
                o_wb_data = i_device4_wb_data;
            end

            if(i_wb_addr[30]) begin //Device 5 Interface (DDR3) (last two bits of address are high)
                o_device5_wb_cyc = i_wb_cyc;
                o_device5_wb_stb = i_wb_stb;
                o_device5_wb_we = i_wb_we;
                o_device5_wb_addr = i_wb_addr; 
                o_device5_wb_data = i_wb_data;
                o_device5_wb_sel = i_wb_sel; 
                o_wb_ack = i_device5_wb_ack;
                o_wb_stall = i_device5_wb_stall;
                o_wb_data = i_device5_wb_data;
            end
        end
        
        // Else access RAM
        else begin  //Device 0 Interface (RAM)
            o_device0_wb_cyc = i_wb_cyc;
            o_device0_wb_stb = i_wb_stb;
            o_device0_wb_we = i_wb_we;
            o_device0_wb_addr = i_wb_addr; 
            o_device0_wb_data = i_wb_data;
            o_device0_wb_sel = i_wb_sel; 
            o_wb_ack = i_device0_wb_ack;
            o_wb_stall = i_device0_wb_stall;
            o_wb_data = i_device0_wb_data;
        end
    end
 
endmodule
module main_memory #(parameter MEMORY_DEPTH=1024) ( //Instruction and Data memory (combined memory)
    input wire i_clk,
    // Instruction Memory
    input wire[$clog2(MEMORY_DEPTH)-1:0] i_inst_addr,
    output reg[31:0] o_inst_out,
    input wire i_stb_inst, // request for instruction
    output reg o_ack_inst, //ack (high if new instruction is now on the bus)
    // Data Memory
    input wire i_wb_cyc,
    input wire i_wb_stb,
    input wire i_wb_we,
    input wire[$clog2(MEMORY_DEPTH)-1:0] i_wb_addr,
    input wire[31:0] i_wb_data,
    input wire[3:0] i_wb_sel,
    output reg o_wb_ack,
    output wire o_wb_stall,
    output reg[31:0] o_wb_data
);
    reg[31:0] memory_regfile[MEMORY_DEPTH/4 - 1:0];
    integer i;
    assign o_wb_stall = 0; // never stall

    initial begin //initialize memory to zero
        o_ack_inst <= 0;
        o_wb_ack <= 0;
        o_inst_out <= 0;
    end
    
    //reading must be registered to be inferred as block ram
    always @(posedge i_clk) begin 
        o_ack_inst <= i_stb_inst; //go high next cycle after receiving request (data o_inst_out is also sent at next cycle)
        o_wb_ack <= i_wb_stb && i_wb_cyc;
        o_inst_out <= memory_regfile[{i_inst_addr>>2}]; //read instruction 
        o_wb_data <= memory_regfile[i_wb_addr[$clog2(MEMORY_DEPTH)-1:2]]; //read data    
    end

    // write data
    always @(posedge i_clk) begin
        if(i_wb_we && i_wb_stb && i_wb_cyc) begin
            if(i_wb_sel[0]) memory_regfile[i_wb_addr[$clog2(MEMORY_DEPTH)-1:2]][7:0] <= i_wb_data[7:0]; 
            if(i_wb_sel[1]) memory_regfile[i_wb_addr[$clog2(MEMORY_DEPTH)-1:2]][15:8] <= i_wb_data[15:8];
            if(i_wb_sel[2]) memory_regfile[i_wb_addr[$clog2(MEMORY_DEPTH)-1:2]][23:16] <= i_wb_data[23:16];
            if(i_wb_sel[3]) memory_regfile[i_wb_addr[$clog2(MEMORY_DEPTH)-1:2]][31:24] <= i_wb_data[31:24];
        end      
        
    end
    
endmodule


module uart #( //UART (TX only)
    parameter CLOCK_FREQ = 12_000_000,//Input clock frequency
    parameter BAUD_RATE  = 9600, //UART Baud rate
    parameter UART_TX_DATA = 8140, //memory-mapped address for TX (write to UART)
    parameter UART_TX_BUSY = 8144, //memory-mapped address to check if TX is busy (has ongoing request)
    parameter UART_RX_BUFFER_FULL = 8148, //memory-mapped address  to check if a read has completed
    parameter UART_RX_DATA = 8152, //memory-mapped address for RX (read the data)
    parameter DBIT = 8, //UART Data Bits
    parameter SBIT = 1 //UART Stop Bits
    )(
        input wire clk,
        input wire rst_n,
        input wire i_wb_cyc,
        input wire i_wb_stb,
        input wire i_wb_we,
        input wire[31:0] i_wb_addr,
        input wire[DBIT - 1:0 ] i_wb_data,
        input wire[3:0] i_wb_sel,
        output reg o_wb_ack,
        output wire o_wb_stall,
        output reg[DBIT - 1:0] o_wb_data,
        input wire uart_rx, //UART RX line
        output wire uart_tx //UART TX line
    );


    localparam DVSR = CLOCK_FREQ/(16*BAUD_RATE);
    localparam DVSR_WIDTH = $clog2(DVSR); //array size needed by DVSR
    localparam SB_TICK = 16*SBIT;
    
     //FSM state declarations
     localparam[1:0] idle=2'd0,
                    start=2'd1,
                    data=2'd2,
                    stop=2'd3;
                    
    reg[DBIT - 1:0] uart_busy;    
    reg tx_done_tick;          
    reg[1:0] state_reg,state_nxt;
    reg[3:0] s_reg,s_nxt; //count to 16 for every data bit
    reg[2:0] n_reg,n_nxt; //count the number of data bits already transmitted
    reg[DBIT - 1:0] din_reg,din_nxt; //stores the word to be transmitted
    reg tx_reg,tx_nxt;
    reg s_tick;
    reg wr_uart;
    reg[1:0] state_reg_rx,state_nxt_rx;
    reg[3:0] s_reg_rx,s_nxt_rx; //check if number of ticks is 7(middle of start bit), or 15(middle of a data bit)
    reg[2:0] n_reg_rx,n_nxt_rx; //checks how many data bits is already passed(value is 7 for last bit)
    reg[7:0] b_reg,b_nxt; //stores 8-bit binary value of received data bits
    reg[7:0] dout; //data read from UART
    reg rx_done_tick; //goes high if a read is done
    reg rx_buffer_full; //goes high if a read is done

    assign o_wb_stall = 0;

    //baud tick generator
     reg[DVSR_WIDTH-1:0] counter=0;
     always @(posedge clk,negedge rst_n) begin
        if(!rst_n) counter<=0;
        else begin
            s_tick=0;
            if(counter == DVSR-1) begin
                s_tick=1;
                counter<=0;
            end
            else begin
                counter<=counter+1;
            end
            
        end
     end
     //Read memory-mapped registers
     always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            o_wb_data <= 0;
            o_wb_ack <= 0;
        end
        else begin
            if(i_wb_stb && i_wb_cyc && !i_wb_we && i_wb_addr == UART_TX_BUSY) begin //read request to UART_TX_BUSY_ADDR (check if there is an ongoing request)
                o_wb_data <= uart_busy;
            end
            else if(i_wb_stb && i_wb_cyc && !i_wb_we && i_wb_addr == UART_RX_BUFFER_FULL) begin //read request to UART_RX_BUFFER_FULL (check if a read is completed)
                o_wb_data <= rx_buffer_full;
            end
            else if(i_wb_stb && i_wb_cyc && !i_wb_we && i_wb_addr == UART_RX_DATA) begin //read request to UART_RX_DATA (read the data)
                o_wb_data <= dout;
            end
            o_wb_ack <= i_wb_stb && i_wb_cyc;
        end
     end
     
     
     /******************************** UART TX ****************************************/

    
     //FSM register operation
     always @(posedge clk,negedge rst_n) begin
        if(!rst_n) begin
            state_reg<=idle;
            s_reg<=0;
            n_reg<=0;
            din_reg<=0;
            tx_reg<=0;
        end
        else begin
            state_reg<=state_nxt;
            s_reg<=s_nxt;
            n_reg<=n_nxt;
            din_reg<=din_nxt;
            tx_reg<=tx_nxt;
        end
     end
     
     //FSM next-state logic
     always @* begin
        state_nxt=state_reg;
        s_nxt=s_reg;
        n_nxt=n_reg;
        din_nxt=din_reg;
        tx_nxt=tx_reg;
        tx_done_tick=0; 
        uart_busy= 1; //uart is busy unless its in idle state
         case(state_reg)
                idle: begin 
                            tx_nxt=1;
                            uart_busy = 0;
                            //start transmit operation when there is a write request to UART_TX_DATA_ADDR and we are in idle
                            if(i_wb_we && i_wb_stb && i_wb_cyc && i_wb_addr == UART_TX_DATA && !uart_busy) begin 
                                din_nxt=i_wb_data;
                                s_nxt=0;
                                state_nxt=start;
                                uart_busy = 1;
                            end
                        end
              start: begin   //wait to finish the start bit
                            tx_nxt=0;
                            if(s_tick==1) begin
                                if(s_reg==15) begin
                                    s_nxt=0;
                                    n_nxt=0;
                                    state_nxt=data;
                                end
                                else s_nxt=s_reg+1;
                            end
                        end
                data: begin  //wait for all data bits to be transmitted serially
                            tx_nxt=din_reg[0];
                            if(s_tick==1) begin
                                if(s_reg==15) begin
                                    din_nxt=din_reg>>1;
                                    s_nxt=0;
                                    if(n_reg==DBIT-1) state_nxt=stop;
                                    else n_nxt=n_reg+1;
                                end
                                else s_nxt=s_reg+1;
                            end
                        end
                stop: begin  //wait to finish the stop bit 
                            tx_nxt=1;
                            if(s_tick==1) begin
                                if(s_reg==SB_TICK-1) begin
                                    tx_done_tick=1;
                                    state_nxt=idle;
                                end
                                else s_nxt=s_reg+1;
                            end
                        end
            default: state_nxt=idle;
         endcase
     end
     assign uart_tx=tx_reg;
    /*********************************************************************************/
    
    /******************************** UART RX ****************************************/
	 
	 //FSM register operation
	 always @(posedge clk,negedge rst_n) begin
		if(!rst_n) begin
			state_reg_rx<=idle;
			s_reg_rx<=0;
			n_reg_rx<=0;
			b_reg<=0;
			dout<=0;
			rx_buffer_full<=0;
		end
		else begin
			state_reg_rx<=state_nxt_rx;
			s_reg_rx<=s_nxt_rx;
			n_reg_rx<=n_nxt_rx;
			b_reg<=b_nxt;	
			if(rx_done_tick) begin
			    dout <= b_reg; //memory-mapped register storing the completed read data	
			    rx_buffer_full <= 1'b1; //memory-mapped register to check if a read is done
			end
			else if(i_wb_stb && i_wb_cyc && !i_wb_we && i_wb_addr == UART_RX_DATA) begin //read request to UART_RX_DATA (read the data)
                rx_buffer_full <= 1'b0;
            end
		end
	 end
	 
	 //FSM next-state logic
	 always @* begin
		state_nxt_rx=state_reg_rx;
		s_nxt_rx=s_reg_rx;
		n_nxt_rx=n_reg_rx;
		b_nxt=b_reg;
		rx_done_tick=0;
		case(state_reg_rx)
			 idle: if(uart_rx==0) begin //wait for start bit(rx of zero)
						s_nxt_rx=0;
						state_nxt_rx=start;
					 end						
			start: if(s_tick==1) begin //wait for middle of start bit
						if(s_reg_rx==7) begin
							s_nxt_rx=0;
							n_nxt_rx=0;
							state_nxt_rx=data;
						end
						else s_nxt_rx=s_reg_rx+1;
					 end
		    data: if(s_tick==1) begin //wait to pass all middle points of every data bits
						if(s_reg_rx==15) begin
							b_nxt={uart_rx,b_reg[7:1]};
							s_nxt_rx=0;
							if(n_reg_rx==DBIT-1) state_nxt_rx=stop;
							else n_nxt_rx=n_reg_rx+1;
						end
						else s_nxt_rx=s_reg_rx+1;
					 end
			 stop: if(s_tick==1) begin  //wait to pass the required stop bits
						if(s_reg_rx==SB_TICK-1) begin
							rx_done_tick=1;
							state_nxt_rx=idle;
						end
  						else s_nxt_rx=s_reg_rx+1;
					 end	
		 default: state_nxt_rx=idle;
		endcase
	 end
	 /*********************************************************************************/
	 
endmodule



module i2c //SCCB mode(no pullups resistors needed) [REPEATED START NOT SUPPORTED]
    #(parameter main_clock=12_000_000, //frequency of clk
                freq=100_000, //i2c freqeuncy
                addr_bytes=2,//addr_bytes=number of bytes of an address
                I2C_START=8100, //write-only memory-mapped address to start i2c (write the i2c slave address)
                I2C_WRITE=8104, //write-only memory-mapped address for sending data to slave
                I2C_READ=8108, //read-only memory-mapped address to read data received from slave (this will also continue reading from slave) 
                I2C_BUSY=8112, //read-only memory-mapped address to check if i2c is busy (cannot accept request)
                I2C_ACK=8116, //read-only memory-mapped address to check if last access has benn acknowledge by slave
                I2C_READ_DATA_READY=8120, //read-only memory-mapped address to check if data to be received from slave is ready
                I2C_STOP=8124 //write-only memory-mapped address to stop i2c (this is persistent thus must be manually turned off after stopping i2c)
    ) 
    (
        input wire clk,
        input wire rst_n,
        // Wishbone Interface
        input wire i_wb_cyc,
        input wire i_wb_stb,
        input wire i_wb_we,
        input wire[31:0] i_wb_addr,
        input wire[7:0] i_wb_data,
        input wire[3:0] i_wb_sel,
        output reg o_wb_ack,
        output wire o_wb_stall,
        output reg[7:0] o_wb_data,
        inout wire scl, sda //i2c bidrectional clock and data line
    ); 
     

    //memory-mapped registers for controlling i2c
    wire[7:0] i2c_busy = {7'b0, !((state_q == idle) || (state_q == stop_or_write) || (state_q == stop_or_read))}; //check if busy (busy unless we are on these states)
    wire[7:0] i2c_read_data_ready = {7'b0, (state_q == stop_or_read)}; //check if data is ready to be read (data is ready ONLY WHEN we are already waiting for another read request!)
    reg[7:0] i2c_ack; //check last access request has been acknowledged by slave
    reg[7:0] i2c_stop; //write non-zero data here to stop current read/write transaction

    
    wire start = i_wb_stb && i_wb_cyc;
    wire[7:0] wr_data = i_wb_data;
    reg ack;
    reg rd_tick;

     localparam full= (main_clock)/(2*freq),
                    half= full/2,           
                    counter_width=$clog2(full);
         
     //FSM state declarations
    localparam[3:0] idle=0,
                    starting=1,
                    packet=2,
                    ack_servant=3,
                    read=4,
                    ack_master=5,
                    stop_1=6,
                    stop_2=7,
                    stop_or_read = 8,
                    stop_or_write = 9;
    reg[3:0] state_q=idle,state_d;
     reg op_q=0,op_d;
     reg[3:0] idx_q=0,idx_d;
     reg[8:0] wr_data_q=0,wr_data_d;
     reg[7:0] rd_data_q,rd_data_d;
     reg scl_q=0,scl_d;
     reg sda_q=0,sda_d;
     reg[counter_width-1:0] counter_q=0,counter_d;
     reg[1:0] addr_bytes_q=0,addr_bytes_d;
     wire scl_lo,scl_hi;
     wire sda_in, sda_out;
    
    assign o_wb_stall = 0;
    //access memory-mapped register
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            i2c_stop <= 0;
            o_wb_ack <= 0;
        end
        else begin
            if(i_wb_stb && i_wb_cyc && i_wb_we && i_wb_addr == I2C_STOP) i2c_stop <= i_wb_data; //write to i2c_stop to stop transaction
            if(i_wb_stb && i_wb_cyc && !i_wb_we && i_wb_addr == I2C_ACK) o_wb_data <= i2c_ack; //read i2c_ack to know if last access request has been ack by slave
            if(i_wb_stb && i_wb_cyc && !i_wb_we && i_wb_addr == I2C_READ_DATA_READY) o_wb_data <= i2c_read_data_ready;//read this to know if data is ready to be read
            if(i_wb_stb && i_wb_cyc && !i_wb_we && i_wb_addr == I2C_BUSY) o_wb_data <= i2c_busy; //read this to know if i2c is still busy
            if(i_wb_stb && i_wb_cyc && !i_wb_we && i_wb_addr == I2C_READ) o_wb_data <= rd_data_q; //read this to know what has been read from slave (make sure I2C_READ_DATA_READY is already high) 

            o_wb_ack <= i_wb_stb && i_wb_cyc; 
        end
    end

    //register operations
     always@(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            state_q<=idle;
            idx_q<=0;
            wr_data_q<=0;
            scl_q<=0;
            sda_q<=0;
            counter_q<=0;
            rd_data_q<=0;
            addr_bytes_q<=0;
            i2c_ack <= 0;
        end
        else begin
            state_q<=state_d;
            op_q<=op_d;
            idx_q<=idx_d;
            wr_data_q<=wr_data_d;
            scl_q<=scl_d;
            sda_q<=sda_d;
            if(i2c_busy[0]) counter_q<=counter_d; //freeze the scl (by freezing the counter) if we are on wait/idle state (not busy states)
            rd_data_q<=rd_data_d;
            addr_bytes_q<=addr_bytes_d;
            i2c_ack <= {7'd0,ack};
        end
     end
     
     
     //free-running clk, freq depends on parameter "freq"
     always @* begin
        counter_d=counter_q+1;
        scl_d=scl_q;
        if(state_q==idle || state_q==starting) scl_d=1'b1;
        else if(counter_q==full[counter_width-1:0]) begin
            counter_d=0;
            scl_d=(scl_q==0)?1'b1:1'b0;
        end
     end
     
    //I2C_START 
     //FSM next-state logic
     always @* begin
        state_d=state_q;
        op_d=op_q;
        idx_d=idx_q;
        wr_data_d=wr_data_q;
        rd_data_d=rd_data_q;
        addr_bytes_d=addr_bytes_q;
        sda_d=sda_q;
        rd_tick=0;
        ack=i2c_ack[0];
        case(state_q)
                    idle: begin //wait for user to start i2c by writing the slave address to I2C_START
                                sda_d=1'b1;
                                addr_bytes_d=addr_bytes; 
                                if(start==1'b1 && i_wb_we && i_wb_addr == I2C_START) begin //wait for a request
                                    wr_data_d={wr_data,1'b1}; //the last 1'b1 is for the ACK coming from the servant("1" means high impedance or "reading")
                                    op_d= (wr_data[0])? 1:0; // if last bit(R/W bit) is one:read operation, else write operation
                                    idx_d=8; //index to be used on transmitting the wr_data serially(MSB first)
                                    state_d=starting;
                                end
                             end
                             
                starting: if(scl_hi) begin //start command, change sda to low while scl is high
                                sda_d=0;
                                state_d=packet;
                             end
                             
                  packet: if(scl_lo) begin //transmit wr_data serially(MSB first)
                                sda_d= (wr_data_q[idx_q]==0)? 0:1'b1;
                                idx_d= idx_q-1;
                                if(idx_q==0) begin
                                    state_d=ack_servant;
                                    idx_d=0;
                                end
                             end
                             
            ack_servant: if(scl_hi) begin //wait for ACK bit response(9th bit) from servant
                                ack=!sda_in; 
                                if(i2c_stop[0]) state_d=stop_1; //master can forcefully stops the transaction (i2c_stop is memory-mapped)
                                else if(op_q/* && addr_bytes_q==0*/) begin //start reading after writing "addr_bytes" of packets for address
                                    idx_d=7;
                                    state_d=read;
                                end
                                else begin //write next packet
                                    state_d = stop_or_write;
                                    idx_d=8;
                                end
                             end
                             
               stop_or_write:  if(i2c_stop[0]) begin //wait until user explicitly say to either stop i2c or continue writing
                                state_d = stop_1;
                            end
                            else if(start && i_wb_we && i_wb_addr == I2C_WRITE) begin//continue writing                   
                                    state_d = packet;
                                    wr_data_d={wr_data,1'b1}; 
                                    addr_bytes_d=addr_bytes_q-1;
                            end

                     read: if(scl_hi) begin //read data from slave(MSB first)
                                rd_data_d[idx_q[2:0]]=sda_in;
                                idx_d=idx_q-1;
                                if(idx_q==0) state_d=ack_master;
                             end
                             
             ack_master: if(scl_lo) begin //master must ACK after receiving data from servant
                                sda_d=1'b0; 
                                if(sda_q==0) begin //one whole bit(two scl_lo) had passed
                                    rd_tick=1;
                                    idx_d=7;
                                    if(i2c_stop[0]) state_d=stop_1; //after receiving data, master can opt to stop
                                    else state_d=stop_or_read;
                                end
                             end
            stop_or_read: if(i2c_stop[0]) begin //wait until user explicitly say to either stop i2c or continue reading
                             state_d = stop_1;
                         end
                         else if(start && !i_wb_we && i_wb_addr == I2C_READ) begin //continue reading when current data is read
                             state_d = read;
                         end

                  stop_1: if(scl_lo) begin 
                                sda_d=1'b0;
                                state_d=stop_2;
                             end
                  stop_2: if(scl_hi) begin
                                sda_d=1'b1;
                                state_d=idle;
                             end
                 default: state_d=idle;
        endcase
     end
     
     //i2c IO logic requires pull-ups (2 logic levels: 0 or Z)
     //assign scl=scl_q? 1'bz:0; //bidiectional logic for pull-up scl
     //assign sda=sda_q? 1'bz:0; //bidirectional logic for pull-up scl
     //assign sda_in=sda;
     
     //We don't used pull-ups here so logic can be 0 or 1 (instead of high
     //impedance). This is similar to SCCB protocol. 
     wire is_reading;
     assign is_reading = (state_q==read || state_q==ack_servant);
     assign sda_out = sda_q;
    
    //Vivado, use IOBUF primitive
    `ifndef ICARUS 
     IOBUF sda_iobuf ( //Vivado IOBUF instantiationGPIO_COUNT-1
            .IO(sda),
            .I(sda_out),//write SDA when is_reading low
            .T(is_reading), 
            .O(sda_in) //read SDA when is_reading high
        );
     `endif
     //Icarus simulator
    `ifdef ICARUS
        assign sda = sda_q;
    `endif

    assign scl = scl_q;
    assign scl_hi= scl_q==1'b1 && counter_q==half[counter_width-1:0] /*&& scl==1'b1*/; //scl is on the middle of a high(1) bit
    assign scl_lo= scl_q==1'b0 && counter_q==half[counter_width-1:0]; //scl is on the middle of a low(0) bit

endmodule



module rv32i_clint #( //Core Logic Interrupt
    parameter CLK_FREQ_MHZ = 12, //input clock frequency in MHz
    // A MTIMER device has two separate base addresses: one for the MTIME register and another for the MTIMECMP registers. 
    parameter MTIME_BASE_ADDRESS = 8008,
              MTIMECMP_BASE_ADDRESS = 8016,
              MSIP_BASE_ADDRESS = 8024
)(
        input wire clk,
        input wire rst_n,
        input wire i_wb_cyc,
        input wire i_wb_stb,
        input wire i_wb_we,
        input wire[31:0] i_wb_addr,
        input wire[31:0] i_wb_data,
        input wire[3:0] i_wb_sel,
        output reg o_wb_ack,
        output wire o_wb_stall,
        output reg[31:0] o_wb_data,
        // Interrupts
        output wire o_timer_interrupt,
        output wire o_software_interrupt
);
    // This is based from RISC-V Advanced Core Local Interruptor
    // Specification: https://github.com/riscv/riscv-aclint/blob/main/riscv-aclint.adoc

    // This RISC-V ACLINT specification defines a set of memory mapped devices which provide 
    // inter-processor interrupts (IPI) and timer functionalities.
    // The MTIMER device provides machine-level timer functionality for a set of HARTs on a RISC-V platform. 
    // It has a single fixed-frequency monotonic time counter (MTIME) register and a time 
    // compare register (MTIMECMP) for each HART connected to the MTIMER device.
    reg[63:0] mtime = 0;
    reg[63:0] mtimecmp = {64{1'b1}};   
    reg msip = 0; //Inter-processor (or software) interrupts
    assign o_wb_stall = 0;

   //READ memory-mapped registers 
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            o_wb_ack <= 0;
            o_wb_data <= 0;
        end
        else begin
            if(i_wb_stb && i_wb_cyc && !i_wb_we) begin //read the memory-mapped register
                if(i_wb_addr == MTIME_BASE_ADDRESS) o_wb_data <= mtime[31:0]; //first half 
                else if(i_wb_addr == MTIME_BASE_ADDRESS + 4) o_wb_data <= mtime[63:32]; //second half
                if(i_wb_addr == MTIMECMP_BASE_ADDRESS) o_wb_data <= mtimecmp[31:0]; //first half
                else if(i_wb_addr == MTIMECMP_BASE_ADDRESS + 4) o_wb_data <= mtimecmp[63:32]; //second half
                if(i_wb_addr == MSIP_BASE_ADDRESS) o_wb_data <= {31'b0, msip}; //machine software interrupt
            end
            o_wb_ack <= i_wb_stb && i_wb_cyc; //wishbone protocol stb-ack mechanism
        end
    end


    //WRITE to memory-mapped registers 
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            mtime <= 64'd0;
            mtimecmp <= {64{1'b1}}; //timer interrupt will be triggered unintentionally if reset at 0 (equal to mtime) 
                                  //thus we set it at highest value (all 1s)
            msip <= 0;
        end
        else begin
            if(i_wb_stb && i_wb_cyc && i_wb_we) begin //write to the memory-mapped registers
                if(i_wb_addr == MTIME_BASE_ADDRESS)  mtime[31:0] <= i_wb_data; //first half 
                else if(i_wb_addr == MTIME_BASE_ADDRESS + 4) mtime[63:32] <= i_wb_data; //second half
                if(i_wb_addr == MTIMECMP_BASE_ADDRESS) mtimecmp[31:0] <= i_wb_data; //first half
                else if(i_wb_addr == MTIMECMP_BASE_ADDRESS + 4) mtimecmp[63:32] <= i_wb_data; //second half
                if(i_wb_addr == MSIP_BASE_ADDRESS) msip <= i_wb_data[0]; //machine software interrupt
            end
            mtime <= mtime + 1'b1; //increment every clock tick (so timer freq is same as cpu clock freq)
        end
    end

    //Volume 2 pg. 44: Platforms provide a 64-bit memory-mapped machine-mode timer compare register (mtimecmp). 
    //A machine timer interrupt becomes pending whenever mtime contains a value greater than or equal to mtimecmp, 
    //treating the values as unsigned integers. The interrupt remains posted until mtimecmp becomes greater than
    //mtime (typically as a result of writing mtimecmp). 
    assign o_timer_interrupt = (mtime >= mtimecmp);

    //Each MSIP register is a 32-bit wide WARL register where the upper 31 bits are wired to zero.
    //The least significant bit is reflected in MSIP of the mip CSR. A machine-level software interrupt 
    //for a HART is pending or cleared by writing 1 or 0 respectively to the corresponding MSIP register.
    assign o_software_interrupt = msip;

endmodule



module gpio #( //UART (TX only)
    parameter GPIO_MODE = 32'hF0, //set if GPIO will be read(0) or write(1) 
    parameter GPIO_READ = 32'hF4, //read from GPIO
    parameter GPIO_WRITE = 32'hF8, //write to GPIO
    parameter GPIO_COUNT = 12
    )(
        input wire clk,
        input wire rst_n,
        // Wishbone Interface
        input wire i_wb_cyc,
        input wire i_wb_stb,
        input wire i_wb_we,
        input wire[31:0] i_wb_addr,
        input wire[GPIO_COUNT-1:0] i_wb_data,
        input wire[3:0] i_wb_sel,
        output reg o_wb_ack,
        output wire o_wb_stall,
        output reg[GPIO_COUNT-1:0] o_wb_data,
        //GPIO
        inout wire[11:0] gpio //gpio pins
    );
       
        
    reg[GPIO_COUNT-1:0] gpio_reg;
    reg[GPIO_COUNT-1:0] gpio_write;
    wire[GPIO_COUNT-1:0] gpio_read;
    reg[GPIO_COUNT-1:0] gpio_mode;

    assign o_wb_stall = 0;
    always @(posedge clk,negedge rst_n) begin
        if(!rst_n) begin
            gpio_write <= 0;
            gpio_mode <= 0;
            gpio_reg <= 0;
        end
        else begin
            if(i_wb_stb && i_wb_we && i_wb_addr == GPIO_MODE) gpio_mode <= i_wb_data; //set mode of the gpio (write(1) or low(0))
            if(i_wb_stb && !i_wb_we && i_wb_addr == GPIO_MODE) o_wb_data <= gpio_mode; //read gpio mode
            if(i_wb_stb && i_wb_we && i_wb_addr == GPIO_WRITE) gpio_write <= i_wb_data; //write to gpio
            if(i_wb_stb && !i_wb_we && i_wb_addr == GPIO_WRITE) o_wb_data <= gpio_write; //read write value to gpio
            if(i_wb_stb && !i_wb_we && i_wb_addr == GPIO_READ) o_wb_data <= gpio_read; //read from gpio
            
            o_wb_ack <= i_wb_stb; 
        end
    end
    
    `ifndef ICARUS 
        genvar i;
        generate
            for(i = 0 ; i < GPIO_COUNT ; i = i+1) begin
                 IOBUF gpio_iobuf ( //Vivado IOBUF instantiation
                    .IO(gpio[i]),
                    .I(gpio_write[i]),//write to GPIO when gpio_mode is high
                    .T(!gpio_mode[i]), 
                    .O(gpio_read[i]) //read from GPIO when gpio_mode is low
                 );
            end
         endgenerate
     `else
         genvar i;
         for(i = 0 ; i < GPIO_COUNT ; i = i+1) begin
	        assign gpio[i] = gpio_mode[i]? gpio_write[i]:1'bz; //in icarus simulation we will only write to the pin
	     end        
     `endif
     
    
        
endmodule










