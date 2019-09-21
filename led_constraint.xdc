## Clock
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports {CLK}];
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports {CLK}]

## Switches
## set_property -dict {PACKAGE_PIN A8 IOSTANDARD LVCMOS33} [get_ports {sw[0]}]
## set_property -dict {PACKAGE_PIN C11 IOSTANDARD LVCMOS33} [get_ports {sw[1]}]
## set_property -dict {PACKAGE_PIN C10 IOSTANDARD LVCMOS33} [get_ports {sw[2]}]
## set_property -dict {PACKAGE_PIN A10 IOSTANDARD LVCMOS33} [get_ports {sw[3]}]

set_property -dict { PACKAGE_PIN D9    IOSTANDARD LVCMOS33 } [get_ports { my_reset }];

## LEDs
set_property -dict {PACKAGE_PIN H5 IOSTANDARD LVCMOS33} [get_ports {led0}];
set_property -dict {PACKAGE_PIN J5 IOSTANDARD LVCMOS33} [get_ports {led1}];
set_property -dict {PACKAGE_PIN T9 IOSTANDARD LVCMOS33} [get_ports {led2}];
## set_property -dict {PACKAGE_PIN T10 IOSTANDARD LVCMOS33} [get_ports {led3}];

## Pmod Header JA
## set_property -dict {PACKAGE_PIN G13 IOSTANDARD LVCMOS33} [get_ports {ja[0]}]
set_property -dict {PACKAGE_PIN G13 IOSTANDARD LVCMOS33} [get_ports {sck}];
## set_property -dict {PACKAGE_PIN B11 IOSTANDARD LVCMOS33} [get_ports {ja[1]}]
set_property -dict {PACKAGE_PIN B11 IOSTANDARD LVCMOS33} [get_ports {mosi}];
## set_property -dict {PACKAGE_PIN A11 IOSTANDARD LVCMOS33} [get_ports {ja[2]}]
## set_property -dict {PACKAGE_PIN D12 IOSTANDARD LVCMOS33} [get_ports {ja[3]}]
## set_property -dict {PACKAGE_PIN D13 IOSTANDARD LVCMOS33} [get_ports {ja[4]}]
## set_property -dict {PACKAGE_PIN B18 IOSTANDARD LVCMOS33} [get_ports {ja[5]}]
## set_property -dict {PACKAGE_PIN A18 IOSTANDARD LVCMOS33} [get_ports {ja[6]}]
## set_property -dict {PACKAGE_PIN K16 IOSTANDARD LVCMOS33} [get_ports {ja[7]}]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
## set_property -dict {PACKAGE_PIN D9 IOSTANDARD LVCMOS33} [get_ports { myreset }];

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]


