## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

## 12 MHz System Clock
set_property -dict {PACKAGE_PIN M9 IOSTANDARD LVCMOS33} [get_ports i_clk]
create_clock -period 83.330 -name sys_clk_pin -waveform {0.000 41.660} -add [get_ports i_clk]

## Push Buttons
set_property -dict { PACKAGE_PIN D2 IOSTANDARD LVCMOS33} [get_ports { i_rst }];


set_property -dict { PACKAGE_PIN L12   IOSTANDARD LVCMOS33 } [get_ports { uart_tx }]; #IO_L6N_T0_D08_VREF_14 Sch=uart_rxd_out
set_property -dict { PACKAGE_PIN K15   IOSTANDARD LVCMOS33 } [get_ports { uart_rx }]; #IO_L5N_T0_D07_14 Sch=uart_txd_in


set_property -dict { PACKAGE_PIN C5    IOSTANDARD LVCMOS33 } [get_ports { i2c_scl }]; #IO_L5P_T0_34 Sch=pio[40]
set_property -dict { PACKAGE_PIN A2    IOSTANDARD LVCMOS33 } [get_ports { i2c_sda }]; #IO_L2N_T0_34 Sch=pio[41]

#set_property -dict { PACKAGE_PIN B2    IOSTANDARD LVCMOS33 } [get_ports { uart_tx }]; #IO_L2P_T0_34 Sch=pio[42]
#set_property -dict { PACKAGE_PIN B1    IOSTANDARD LVCMOS33 } [get_ports { uart_rx }]; #IO_L4N_T0_34 Sch=pio[43]

set_property -dict { PACKAGE_PIN L1    IOSTANDARD LVCMOS33 } [get_ports { gpio_pins[0] }]; #IO_L18N_T2_34 Sch=pio[01]
set_property -dict { PACKAGE_PIN M4    IOSTANDARD LVCMOS33 } [get_ports { gpio_pins[1] }]; #IO_L19P_T3_34 Sch=pio[02]
set_property -dict { PACKAGE_PIN M3    IOSTANDARD LVCMOS33 } [get_ports { gpio_pins[2] }]; #IO_L19N_T3_VREF_34 Sch=pio[03]
set_property -dict { PACKAGE_PIN N2    IOSTANDARD LVCMOS33 } [get_ports { gpio_pins[3] }]; #IO_L20P_T3_34 Sch=pio[04]
set_property -dict { PACKAGE_PIN M2    IOSTANDARD LVCMOS33 } [get_ports { gpio_pins[4] }]; #IO_L20N_T3_34 Sch=pio[05]
set_property -dict { PACKAGE_PIN P3    IOSTANDARD LVCMOS33 } [get_ports { gpio_pins[5] }]; #IO_L21P_T3_DQS_34 Sch=pio[06]
set_property -dict { PACKAGE_PIN N3    IOSTANDARD LVCMOS33 } [get_ports { gpio_pins[6] }]; #IO_L21N_T3_DQS_34 Sch=pio[07]
set_property -dict { PACKAGE_PIN P1    IOSTANDARD LVCMOS33 } [get_ports { gpio_pins[7] }]; #IO_L22P_T3_34 Sch=pio[08]

set_property -dict { PACKAGE_PIN E2    IOSTANDARD LVCMOS33 } [get_ports { gpio_pins[8] }]; #IO_L8P_T1_34 Sch=led[1]
set_property -dict { PACKAGE_PIN K1    IOSTANDARD LVCMOS33 } [get_ports { gpio_pins[9] }]; #IO_L16P_T2_34 Sch=led[2]
set_property -dict { PACKAGE_PIN J1    IOSTANDARD LVCMOS33 } [get_ports { gpio_pins[10] }]; #IO_L16N_T2_34 Sch=led[3]
set_property -dict { PACKAGE_PIN E1    IOSTANDARD LVCMOS33 } [get_ports { gpio_pins[11] }]; #IO_L8N_T1_34 Sch=led[4]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
