// Core plus memory

`timescale 1ns / 1ps
`default_nettype none
`define ICARUS

//complete package containing the rv32i_core, RAM, and IO peripherals (I2C and UART)
module rv32i_soc #(parameter CLK_FREQ_MHZ=12, PC_RESET=32'h00_00_00_00, TRAP_ADDRESS=32'h00_00_00_00, ZICSR_EXTENSION=1, MEMORY_DEPTH=8192) ( 
    input wire i_clk,
    input wire i_rst,
    //UART
    input wire uart_rx,
    output wire uart_tx,
    //I2C
    inout wire i2c_sda,
    inout wire i2c_scl
    );

    
    //Instruction Memory Interface
    wire[31:0] inst; 
    wire[31:0] iaddr;  
    wire i_stb_inst;
    wire o_ack_inst;
    
    //Data Memory Interface
    wire[31:0] din; //data r
    wire[31:0] dout; //data to be stored to memory
    wire[31:0] daddr; //address of data memory for store/load
    wire[3:0] wr_mask; //write mask control
    wire wr_en; //write enable 
    wire i_stb_data;
    wire o_ack_data;
    
    //Interrupts
    wire i_external_interrupt; //interrupt from external source
    wire i_software_interrupt = 0; //interrupt from software
    
    // Timer Interrupt
    wire i_mtime_wr = 0; //write to mtime
    wire i_mtimecmp_wr = 0;  //write to mtimecmp
    wire[63:0] i_mtime_din = 0; //data to be written to mtime
    wire[63:0] i_mtimecmp_din = 0; //data to be written to mtimecmp
    
    //Memory Wrapper
    wire[31:0] o_device0_data_addr;
    wire[31:0] o_device0_wdata;
    wire[31:0] i_device0_rdata;
    wire o_device0_wr_en;
    wire[3:0]  o_device0_wr_mask;
    wire o_device0_stb_data;
    wire i_device0_ack_data;
    wire[31:0] o_device1_data_addr;
    wire[31:0] o_device1_wdata;
    wire[31:0] i_device1_rdata;
    wire o_device1_wr_en;
    wire[3:0] o_device1_wr_mask;
    wire o_device1_stb_data;
    wire i_device1_ack_data;
    wire[31:0] o_device2_data_addr;
    wire[31:0] o_device2_wdata;
    wire[31:0] i_device2_rdata;
    wire o_device2_wr_en;
    wire[3:0] o_device2_wr_mask;
    wire o_device2_stb_data;
    wire i_device2_ack_data;

    rv32i_core #(.PC_RESET(PC_RESET),.CLK_FREQ_MHZ(CLK_FREQ_MHZ), .TRAP_ADDRESS(TRAP_ADDRESS), .ZICSR_EXTENSION(ZICSR_EXTENSION)) m0( //main RV32I core
        .i_clk(i_clk),
        .i_rst_n(!i_rst),
        //Instruction Memory Interface
        .i_inst(inst), //32-bit instruction
        .o_iaddr(iaddr), //address of instruction 
        .o_stb_inst(i_stb_inst), //request for read access to instruction memory
        .i_ack_inst(o_ack_inst),  //ack (high if new instruction is ready)
        //Data Memory Interface
        .i_din(din), //data retrieved from memory
        .o_dout(dout), //data to be stored to memory
        .o_daddr(daddr), //address of data memory for store/load
        .o_wr_mask(wr_mask), //write mask control
        .o_wr_en(wr_en), //write enable 
        .o_stb_data(i_stb_data), //request for read/write access to data memory
        .i_ack_data(o_ack_data), //ack by data memory (high when read data is ready or when write data is already written)
        //Interrupts
        .i_external_interrupt(i_external_interrupt), //interrupt from external source
        .i_software_interrupt(i_software_interrupt), //interrupt from software
        // Timer Interrupt
        .i_mtime_wr(i_mtime_wr), //write to mtime
        .i_mtimecmp_wr(i_mtimecmp_wr),  //write to mtimecmp
        .i_mtime_din(i_mtime_din), //data to be written to mtime
        .i_mtimecmp_din(i_mtimecmp_din) //data to be written to mtimecmp
     );
        
    memory_wrapper wrapper( //decodes address and access the corresponding memory-mapped device
        //RISC-V Core
        .i_data_addr(daddr),
        .i_wdata(dout),
        .o_rdata(din),
        .i_wr_en(wr_en),
        .i_wr_mask(wr_mask),
        .i_stb_data(i_stb_data),
        .o_ack_data(o_ack_data),

        //Device 0 Interface (RAM)
        .o_device0_data_addr(o_device0_data_addr),
        .o_device0_wdata(o_device0_wdata),
        .i_device0_rdata(i_device0_rdata),
        .o_device0_wr_en(o_device0_wr_en),
        .o_device0_wr_mask(o_device0_wr_mask),
        .o_device0_stb_data(o_device0_stb_data),
        .i_device0_ack_data(i_device0_ack_data),

        //Device 1 Interface (UART)
        .o_device1_data_addr(o_device1_data_addr),
        .o_device1_wdata(o_device1_wdata),
        .i_device1_rdata(i_device1_rdata),
        .o_device1_wr_en(o_device1_wr_en),
        .o_device1_wr_mask(o_device1_wr_mask),
        .o_device1_stb_data(o_device1_stb_data),
        .i_device1_ack_data(i_device1_ack_data),
        
        //Device 2 Interface (I2C)
        .o_device2_data_addr(o_device2_data_addr),
        .o_device2_wdata(o_device2_wdata),
        .i_device2_rdata(i_device2_rdata),
        .o_device2_wr_en(o_device2_wr_en),
        .o_device2_wr_mask(o_device2_wr_mask),
        .o_device2_stb_data(o_device2_stb_data),
        .i_device2_ack_data(i_device2_ack_data)
    );   

     main_memory #(.MEMORY_DEPTH(MEMORY_DEPTH)) m1( //Instruction and Data memory (combined memory) [memory-mapped to <8100]
        .i_clk(i_clk),
        // Instruction Memory
        .i_inst_addr(iaddr[$clog2(MEMORY_DEPTH)-1:0]),
        .o_inst_out(inst),
        .i_stb_inst(i_stb_inst), 
        .o_ack_inst(o_ack_inst), 
        // Data Memory
        .i_data_addr(o_device0_data_addr[$clog2(MEMORY_DEPTH)-1:0]),
        .i_data_in(o_device0_wdata),
        .i_wr_mask(o_device0_wr_mask),
        .i_wr_en(o_device0_wr_en),
        .i_stb_data(o_device0_stb_data),
        .o_ack_data(i_device0_ack_data),
        .o_data_out(i_device0_rdata)
    );

    uart #( .CLOCK_FREQ(CLK_FREQ_MHZ*1_000_000), //UART (TX only) [memory-mapped to >=8100]
            .BAUD_RATE( //UART Baud rate
              `ifdef ICARUS
               2_000_000 //faster simulation
               `else 
               9600 //9600 Baud
               `endif),
            .UART_TX_DATA_ADDR(8140), //memory-mapped address for TX
            .UART_TX_BUSY_ADDR(8144), //memory-mapped address to check if TX is busy (has ongoing request)
            .DBIT(8), //UART Data Bits
            .SBIT(1) //UART Stop Bits
     ) uart
     (
      .clk(i_clk),
      .rst_n(!i_rst),
      .uart_rw_address(o_device1_data_addr), //read/write address (access the memory-mapped registers for controlling UART)
      .uart_wdata(o_device1_wdata[7:0]), //TX data
      .uart_wr_en(o_device1_wr_en), //write-enable
      .uart_rx(uart_rx), //UART RX line
      .uart_tx(uart_tx), //UART TX line
      .uart_rdata(i_device1_rdata[7:0]), //data read from memory-mapped register 
      .uart_interrupt_request(i_external_interrupt), 
      .o_ack_data(i_device1_ack_data), //request to access UART
      .i_stb_data(o_device1_stb_data) //acknowledge by UART
      );

    i2c #(.main_clock(CLK_FREQ_MHZ*1_000_000), //SCCB mode(no pullups resistors needed) [memory-mapped to >=8000,<8100]
          .freq( //i2c freqeuncy
          `ifdef ICARUS
           2_000_000 //faster simulation
           `else 
           100_000 //100KHz
           `endif),
          .addr_bytes(1), //addr_bytes=number of bytes of an address
          .I2C_START(8040), //write-only memory-mapped address to start i2c (write the i2c slave address)
          .I2C_WRITE(8044), //write-only memory-mapped address for sending data to slave
          .I2C_READ(8048), //read-only memory-mapped address to read data received from slave (this will also continue reading from slave) 
          .I2C_BUSY(8052), //read-only memory-mapped address to check if i2c is busy (cannot accept request)
          .I2C_ACK(8056), //read-only memory-mapped address to check if last access has benn acknowledge by slave
          .I2C_READ_DATA_READY(8060), //read-only memory-mapped address to check if data to be received from slave is ready
          .I2C_STOP(8064) //write-only memory-mapped address to stop i2c (this is persistent thus must be manually turned off after stopping i2c)
      ) i2c
      (
        .clk(i_clk),
        .rst_n(!i_rst),
        .i2c_rw_address(o_device2_data_addr), //read/write address (access the memory-mapped registers for controlling i2c)
        .i2c_wdata(o_device2_wdata[7:0]),  //data to be written to slave or to memory-mapped registers of i2c
        .i2c_rdata(i_device2_rdata[7:0]),  //data retrieved from slave or from the memory-mapped registers of i2c
        .i2c_wr_en(o_device2_wr_en), //write-enable
        .i_stb_data(o_device2_stb_data), //request to access i2c
        .o_ack_data(i_device2_ack_data), //acknowledge by i2c
        .scl(i2c_scl), //i2c bidrectional clock line
        .sda(i2c_sda) //i2c bidrectional data line
    );

endmodule


module memory_wrapper ( //decodes address and access the corresponding memory-mapped device
    //RISC-V Core
    input wire[31:0] i_data_addr,
    input wire[31:0] i_wdata,
    output reg[31:0] o_rdata,
    input wire i_wr_en,
    input wire[3:0] i_wr_mask,
    input wire i_stb_data,
    output reg o_ack_data,

    //Device 0 Interface (RAM)
    output reg[31:0] o_device0_data_addr,
    output reg[31:0] o_device0_wdata,
    input wire[31:0] i_device0_rdata,
    output reg o_device0_wr_en,
    output reg[3:0] o_device0_wr_mask,
    output reg o_device0_stb_data,
    input wire i_device0_ack_data,

    //Device 1 Interface (UART)
    output reg[31:0] o_device1_data_addr,
    output reg[31:0] o_device1_wdata,
    input wire[31:0] i_device1_rdata,
    output reg o_device1_wr_en,
    output reg[3:0] o_device1_wr_mask,
    output reg o_device1_stb_data,
    input wire i_device1_ack_data,

    //Device 2 Interface (I2C)
    output reg[31:0] o_device2_data_addr,
    output reg[31:0] o_device2_wdata,
    input wire[31:0] i_device2_rdata,
    output reg o_device2_wr_en,
    output reg[3:0] o_device2_wr_mask,
    output reg o_device2_stb_data,
    input wire i_device2_ack_data
);


    always @* begin 
		o_device0_data_addr = 0; 
		o_device0_wdata = 0;
		o_rdata = 0;
		o_device0_wr_en = 0;
		o_device0_wr_mask = 0;
		o_device0_stb_data = 0;
		o_ack_data = 0;
			
        if(i_data_addr < 8000) begin  //Device 0 Interface (RAM)
            o_device0_data_addr = i_data_addr; 
            o_device0_wdata = i_wdata;
            o_rdata = i_device0_rdata;
            o_device0_wr_en = i_wr_en;
            o_device0_wr_mask = i_wr_mask;
            o_device0_stb_data = i_stb_data;
            o_ack_data = i_device0_ack_data;
        end
        else begin
            o_device0_data_addr = 0; 
            o_device0_wdata = 0;
            o_device0_wr_en = 0;
            o_device0_wr_mask = 0;
            o_device0_stb_data = 0;
        end
        
        if(i_data_addr >= 8100) begin //Device 1 Interface (UART) 
            o_device1_data_addr = i_data_addr; 
            o_device1_wdata = i_wdata;
            o_rdata = i_device1_rdata;
            o_device1_wr_en = i_wr_en;
            o_device1_wr_mask = i_wr_mask;
            o_device1_stb_data = i_stb_data;
            o_ack_data = i_device1_ack_data;
        end
        else begin
            o_device1_data_addr = 0; 
            o_device1_wdata = 0;
            o_device1_wr_en = 0;
            o_device1_wr_mask = 0;
            o_device1_stb_data = 0;
        end
        
        if(i_data_addr >= 8000 && i_data_addr < 8100) begin //Device 2 Interface (I2C) 
            o_device2_data_addr = i_data_addr; 
            o_device2_wdata = i_wdata;
            o_rdata = i_device2_rdata;
            o_device2_wr_en = i_wr_en;
            o_device2_wr_mask = i_wr_mask;
            o_device2_stb_data = i_stb_data;
            o_ack_data = i_device2_ack_data;
        end
        else begin
            o_device2_data_addr = 0; 
            o_device2_wdata = 0;
            o_device2_wr_en = 0;
            o_device2_wr_mask = 0;
            o_device2_stb_data = 0;
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
    input wire[$clog2(MEMORY_DEPTH)-1:0] i_data_addr,
    input wire[31:0] i_data_in,
    input wire[3:0] i_wr_mask,
    input wire i_wr_en,
    input wire i_stb_data,
    output reg o_ack_data,
    output reg[31:0] o_data_out
);
    reg[31:0] memory_regfile[MEMORY_DEPTH/4 - 1:0];
    integer i;
    
    initial begin //initialize memory to zero
        $readmemh("memory.mem",memory_regfile); //initialize memory
        o_ack_inst <= 0;
        o_ack_data <= 0;
        o_inst_out <= 0;
    end
    
    //reading must be registered to be inferred as block ram
    always @(posedge i_clk) begin 
        o_ack_inst <= i_stb_inst; //go high next cycle after receiving request (data o_inst_out is also sent at next cycle)
        o_ack_data <= i_stb_data;
        o_inst_out <= memory_regfile[{i_inst_addr>>2}]; //read instruction 
        o_data_out <= memory_regfile[i_data_addr[$clog2(MEMORY_DEPTH)-1:2]]; //read data    
    end

    // write data
    always @(posedge i_clk) begin
        if(i_wr_en) begin
            if(i_wr_mask[0]) memory_regfile[i_data_addr[$clog2(MEMORY_DEPTH)-1:2]][7:0] <= i_data_in[7:0]; 
            if(i_wr_mask[1]) memory_regfile[i_data_addr[$clog2(MEMORY_DEPTH)-1:2]][15:8] <= i_data_in[15:8];
            if(i_wr_mask[2]) memory_regfile[i_data_addr[$clog2(MEMORY_DEPTH)-1:2]][23:16] <= i_data_in[23:16];
            if(i_wr_mask[3]) memory_regfile[i_data_addr[$clog2(MEMORY_DEPTH)-1:2]][31:24] <= i_data_in[31:24];
        end      
        
    end
    
endmodule


module uart #( //UART (TX only)
    parameter CLOCK_FREQ = 12_000_000,//Input clock frequency
    parameter BAUD_RATE  = 9600, //UART Baud rate
    parameter UART_TX_DATA_ADDR = 8140, //memory-mapped address for TX
    parameter UART_TX_BUSY_ADDR = 8144, //memory-mapped address to check if TX is busy (has ongoing request)
    parameter DBIT = 8, //UART Data Bits
    parameter SBIT = 1 //UART Stop Bits
    )(
        input wire clk,
        input wire rst_n,
        input wire[31:0] uart_rw_address, //read/write address (access the memory-mapped registers for controlling UART)
        input wire[DBIT - 1:0 ] uart_wdata, //TX data
        input wire uart_wr_en, //write-enable
        input wire uart_rx, //UART RX line
        output wire uart_tx, //UART TX line
        output reg[DBIT - 1:0] uart_rdata, //data read from memory-mapped register 
        output wire uart_interrupt_request,
        input wire i_stb_data, //request to access UART
        output reg o_ack_data //acknowledge by UART
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
    
     //Read request
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            uart_rdata <= 0;
            o_ack_data <= 0;
        end
        else begin
            if(i_stb_data && !uart_wr_en && uart_rw_address == UART_TX_BUSY_ADDR) begin //read request to UART_TX_BUSY_ADDR (check if there is an ongoing request)
                uart_rdata <= uart_busy;
            end
            o_ack_data <= i_stb_data;
        end
    end
	
    //baud tick generator
	 reg[DVSR_WIDTH-1:0] counter=0;
	 always @(posedge clk,negedge rst_n) begin
		if(!rst_n) counter<=0;
		else begin
			s_tick=0;
			if(counter==DVSR-1) begin
				s_tick=1;
				counter<=0;
			end
			else begin
				counter<=counter+1;
			end
			
		end
	 end
	 
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
							if(uart_wr_en && i_stb_data && uart_rw_address == UART_TX_DATA_ADDR && !uart_busy) begin 
								din_nxt=uart_wdata;
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
        input   wire        clk,
        input   wire        rst_n,
        input   wire [31:0] i2c_rw_address, //read/write address (access the memory-mapped registers for controlling i2c)
        input   wire [7:0 ] i2c_wdata, //data to be written to slave or to memory-mapped registers of i2c
        output reg [7:0] i2c_rdata, //data retrieved from slave or from the memory-mapped registers of i2c
        input   wire        i2c_wr_en, //write-enable
	    inout wire scl, sda, //i2c bidrectional clock and data line
        output reg o_ack_data, //acknowledge by i2c
        input wire i_stb_data //request to access i2c
    ); 
	 

    //memory-mapped registers for controlling i2c
    wire[7:0] i2c_busy = !((state_q == idle) || (state_q == stop_or_write) || (state_q == stop_or_read)); //check if busy (busy unless we are on these states)
    wire[7:0] i2c_read_data_ready = (state_q == stop_or_read); //check if data is ready to be read (data is ready ONLY WHEN we are already waiting for another read request!)
    reg[7:0] i2c_ack; //check last access request has been acknowledged by slave
    reg[7:0] i2c_stop; //write non-zero data here to stop current read/write transaction

    
	wire start = i_stb_data;
    wire[7:0] wr_data = i2c_wdata;
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
    
    //access memory-mapped register
    always @(posedge clk, negedge rst_n) begin
        if(!rst_n) begin
            i2c_stop <= 0;
        end
        else begin
            if(i_stb_data && i2c_wr_en && i2c_rw_address == I2C_STOP) i2c_stop <= i2c_wdata; //write to i2c_stop to stop transaction
            if(i_stb_data && !i2c_wr_en && i2c_rw_address == I2C_ACK) i2c_rdata <= i2c_ack; //read i2c_ack to know if last access request has been ack by slave
            if(i_stb_data && !i2c_wr_en && i2c_rw_address == I2C_READ_DATA_READY) i2c_rdata <= i2c_read_data_ready;//read this to know if data is ready to be read
            if(i_stb_data && !i2c_wr_en && i2c_rw_address == I2C_BUSY) i2c_rdata <= i2c_busy; //read this to know if i2c is still busy
            if(i_stb_data && !i2c_wr_en && i2c_rw_address == I2C_READ) i2c_rdata <= rd_data_q; //read this to know what has been read from slave (make sure I2C_READ_DATA_READY is already high) 

            o_ack_data <= i_stb_data; 
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
            if(i2c_busy) counter_q<=counter_d; //freeze the scl (by freezing the counter) if we are on wait/idle state (not busy states)
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
		else if(counter_q==full) begin
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
		ack=i2c_ack;
		case(state_q)
					idle: begin	//wait for user to start i2c by writing the slave address to I2C_START
								sda_d=1'b1;
								addr_bytes_d=addr_bytes; 
								if(start==1'b1 && i2c_wr_en && i2c_rw_address == I2C_START) begin //wait for a request
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
								if(i2c_stop) state_d=stop_1; //master can forcefully stops the transaction (i2c_stop is memory-mapped)
								else if(op_q && addr_bytes_q==0) begin //start reading after writing "addr_bytes" of packets for address
									idx_d=7;
									state_d=read;
								end
								else begin //write next packet
                                    state_d = stop_or_write;
									idx_d=8;
								end
							 end
							 
               stop_or_write:  if(i2c_stop == 1) begin //wait until user explicitly say to either stop i2c or continue writing
                                state_d = stop_1;
                            end
                            else if(start && i2c_wr_en && i2c_rw_address == I2C_WRITE) begin//continue writing                   
                                    state_d = packet;
                                    wr_data_d={wr_data,1'b1}; 
                                    addr_bytes_d=addr_bytes_q-1;
                            end

					 read: if(scl_hi) begin //read data from slave(MSB first)
								rd_data_d[idx_q]=sda_in;
								idx_d=idx_q-1;
								if(idx_q==0) state_d=ack_master;
							 end
							 
			 ack_master: if(scl_lo) begin //master must ACK after receiving data from servant
								sda_d=1'b0; 
								if(sda_q==0) begin //one whole bit(two scl_lo) had passed
									rd_tick=1;
									idx_d=7;
									if(i2c_stop) state_d=stop_1; //after receiving data, master can opt to stop
									else state_d=stop_or_read;
                                end
							 end
            stop_or_read: if(i2c_stop == 1) begin //wait until user explicitly say to either stop i2c or continue reading
                             state_d = stop_1;
                         end
                         else if(start && !i2c_wr_en && i2c_rw_address == I2C_READ) begin //continue reading
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
	 IOBUF sda_iobuf ( //Vivado IOBUF instantiation
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
	assign scl_hi= scl_q==1'b1 && counter_q==half /*&& scl==1'b1*/; //scl is on the middle of a high(1) bit
	assign scl_lo= scl_q==1'b0 && counter_q==half; //scl is on the middle of a low(0) bit

endmodule




