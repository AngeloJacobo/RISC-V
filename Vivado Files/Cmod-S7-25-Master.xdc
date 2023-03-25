## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

## 12 MHz System Clock
set_property -dict {PACKAGE_PIN M9 IOSTANDARD LVCMOS33} [get_ports i_clk]
create_clock -period 83.330 -name sys_clk_pin -waveform {0.000 41.660} -add [get_ports i_clk]

## Push Buttons
set_property -dict {PACKAGE_PIN D2 IOSTANDARD LVCMOS33} [get_ports { i_rst }]



#set_property -dict { PACKAGE_PIN L1    IOSTANDARD LVCMOS33 } [get_ports { uart_tx }]; #IO_L18N_T2_34 Sch=pio[01]
set_property -dict { PACKAGE_PIN L12   IOSTANDARD LVCMOS33 } [get_ports { uart_tx }]; #IO_L6N_T0_D08_VREF_14 Sch=uart_rxd_out

set_property -dict { PACKAGE_PIN M3    IOSTANDARD LVCMOS33 } [get_ports { i2c_sda }]; #IO_L19N_T3_VREF_34 Sch=pio[03]
set_property -dict { PACKAGE_PIN N2    IOSTANDARD LVCMOS33 } [get_ports { i2c_scl }]; #IO_L20P_T3_34 Sch=pio[04]



set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
