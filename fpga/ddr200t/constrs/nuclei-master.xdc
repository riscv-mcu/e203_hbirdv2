set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

#####               create clock              #####



set_property -dict { PACKAGE_PIN W19    IOSTANDARD LVCMOS33 } [get_ports { CLK100MHZ }]; 
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {CLK100MHZ}];

set_property -dict { PACKAGE_PIN Y18    IOSTANDARD LVCMOS33 } [get_ports { CLK32768KHZ }]; 
create_clock -add -name sys_clk_pin -period 30517.58 -waveform {0 15258.79} [get_ports {CLK32768KHZ}];


set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets dut_io_pads_jtag_TCK_i_ival]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets IOBUF_jtag_TCK/O]


#####            rst define           #####

set_property PACKAGE_PIN T6  [get_ports fpga_rst  ]
set_property PACKAGE_PIN P20 [get_ports mcu_rst   ]

#####                spi0 define               #####
set_property PACKAGE_PIN W16 [get_ports  qspi0_cs    ]
set_property PACKAGE_PIN W15 [get_ports  qspi0_sck   ]
set_property PACKAGE_PIN U16 [get_ports {qspi0_dq[3]}]
set_property PACKAGE_PIN T16 [get_ports {qspi0_dq[2]}]
set_property PACKAGE_PIN T14 [get_ports {qspi0_dq[1]}]
set_property PACKAGE_PIN T15 [get_ports {qspi0_dq[0]}]

#####               MCU JTAG define           #####
set_property PACKAGE_PIN N17 [get_ports mcu_TDO]
set_property PACKAGE_PIN P15 [get_ports mcu_TCK]
set_property PACKAGE_PIN T18 [get_ports mcu_TDI]
set_property PACKAGE_PIN P17 [get_ports mcu_TMS]
set_property KEEPER true [get_ports mcu_TMS]

#####                PMU define               #####
set_property PACKAGE_PIN U15 [get_ports pmu_paden ]
set_property PACKAGE_PIN V15 [get_ports pmu_padrst]
set_property PACKAGE_PIN N15 [get_ports mcu_wakeup]


#####                gpioA define              #####
## sw_in 4
set_property PACKAGE_PIN D20  [get_ports {gpioA[31]}]
## sw_in 3
set_property PACKAGE_PIN E18  [get_ports {gpioA[30]}]
## sw_in 2
set_property PACKAGE_PIN E21  [get_ports {gpioA[29]}]
## sw_in 1
set_property PACKAGE_PIN E17  [get_ports {gpioA[28]}]
## sw_in 0
set_property PACKAGE_PIN M17  [get_ports {gpioA[27]}]
## LED 7
set_property PACKAGE_PIN C17  [get_ports {gpioA[26]}]     
## LED 6
set_property PACKAGE_PIN D19  [get_ports {gpioA[25]}]     
## LED 5
set_property PACKAGE_PIN D17  [get_ports {gpioA[24]}]     
## LED 4
set_property PACKAGE_PIN D21  [get_ports {gpioA[23]}]     
## LED 3
set_property PACKAGE_PIN E19  [get_ports {gpioA[22]}]     
## LED 2
set_property PACKAGE_PIN F18  [get_ports {gpioA[21]}]     
## LED 1
set_property PACKAGE_PIN E22  [get_ports {gpioA[20]}]     
## LED 0
set_property PACKAGE_PIN J16  [get_ports {gpioA[19]}]     
## TFT rs
set_property PACKAGE_PIN K16  [get_ports {gpioA[18]}]     
## UART TX
set_property PACKAGE_PIN R17  [get_ports {gpioA[17]}]
## UART RX
set_property PACKAGE_PIN P16  [get_ports {gpioA[16]}]
## EEPROM SDA
set_property PACKAGE_PIN N14  [get_ports {gpioA[15]}]
## EEPROM SCL
set_property PACKAGE_PIN Y17  [get_ports {gpioA[14]}]
## JP63
set_property PACKAGE_PIN AB12 [get_ports {gpioA[13]}]     
## JP62
set_property PACKAGE_PIN Y11  [get_ports {gpioA[12]}]     
## TFT sdi
set_property PACKAGE_PIN M15  [get_ports {gpioA[11]}]
## TFT sdo
set_property PACKAGE_PIN L15  [get_ports {gpioA[10]}]
## TFT cs
set_property PACKAGE_PIN L14  [get_ports {gpioA[9]}]      
## TFT scl
set_property PACKAGE_PIN M16  [get_ports {gpioA[8]}]
## key_in 4
set_property PACKAGE_PIN A15  [get_ports {gpioA[7]}]
## key_in 3
set_property PACKAGE_PIN A13  [get_ports {gpioA[6]}]
## key_in 2
set_property PACKAGE_PIN B17  [get_ports {gpioA[5]}]
## key_in 1
set_property PACKAGE_PIN A16  [get_ports {gpioA[4]}]
## key_in 0
set_property PACKAGE_PIN A14  [get_ports {gpioA[3]}]
## RGB B
set_property PACKAGE_PIN B13  [get_ports {gpioA[2]}]
## RGB G
set_property PACKAGE_PIN D14  [get_ports {gpioA[1]}]
## RGB R
set_property PACKAGE_PIN E13  [get_ports {gpioA[0]}]      


#####                gpioB define              #####
set_property PACKAGE_PIN W17  [get_ports {gpioB[31]}]
set_property PACKAGE_PIN AA18 [get_ports {gpioB[30]}]
set_property PACKAGE_PIN AB18 [get_ports {gpioB[29]}]
set_property PACKAGE_PIN U17  [get_ports {gpioB[28]}]
set_property PACKAGE_PIN U18  [get_ports {gpioB[27]}]
set_property PACKAGE_PIN P14  [get_ports {gpioB[26]}]
set_property PACKAGE_PIN R14  [get_ports {gpioB[25]}]
set_property PACKAGE_PIN R18  [get_ports {gpioB[24]}]
set_property PACKAGE_PIN V20  [get_ports {gpioB[23]}]
set_property PACKAGE_PIN W20  [get_ports {gpioB[22]}]
set_property PACKAGE_PIN Y19  [get_ports {gpioB[21]}]
set_property PACKAGE_PIN V18  [get_ports {gpioB[20]}]
set_property PACKAGE_PIN V19  [get_ports {gpioB[19]}]
set_property PACKAGE_PIN AA19 [get_ports {gpioB[18]}]
set_property PACKAGE_PIN AB20 [get_ports {gpioB[17]}]  
set_property PACKAGE_PIN V17  [get_ports {gpioB[16]}]  
set_property PACKAGE_PIN V22  [get_ports {gpioB[15]}]
set_property PACKAGE_PIN T21  [get_ports {gpioB[14]}]
set_property PACKAGE_PIN U21  [get_ports {gpioB[13]}]
set_property PACKAGE_PIN P19  [get_ports {gpioB[12]}]
set_property PACKAGE_PIN R19  [get_ports {gpioB[11]}]
set_property PACKAGE_PIN N13  [get_ports {gpioB[10]}]
set_property PACKAGE_PIN T20  [get_ports {gpioB[9]}]
set_property PACKAGE_PIN W21  [get_ports {gpioB[8]}]
set_property PACKAGE_PIN U20  [get_ports {gpioB[7]}]
set_property PACKAGE_PIN AB22 [get_ports {gpioB[6]}]
set_property PACKAGE_PIN AB21 [get_ports {gpioB[5]}]
set_property PACKAGE_PIN Y22  [get_ports {gpioB[4]}]
set_property PACKAGE_PIN Y21  [get_ports {gpioB[3]}]
set_property PACKAGE_PIN AA21 [get_ports {gpioB[2]}]
set_property PACKAGE_PIN AA20 [get_ports {gpioB[1]}]
set_property PACKAGE_PIN W22  [get_ports {gpioB[0]}]

#####            clock & rst define           #####

set_property IOSTANDARD LVCMOS15 [get_ports fpga_rst  ]
set_property IOSTANDARD LVCMOS33 [get_ports mcu_rst   ]


#####                spi0 define               #####
set_property IOSTANDARD LVCMOS33 [get_ports  qspi0_cs    ]
set_property IOSTANDARD LVCMOS33 [get_ports  qspi0_sck   ]
set_property IOSTANDARD LVCMOS33 [get_ports {qspi0_dq[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {qspi0_dq[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {qspi0_dq[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {qspi0_dq[0]}]


#####               MCU JTAG define           #####
set_property IOSTANDARD LVCMOS33 [get_ports mcu_TDO]
set_property IOSTANDARD LVCMOS33 [get_ports mcu_TCK]
set_property IOSTANDARD LVCMOS33 [get_ports mcu_TDI]
set_property IOSTANDARD LVCMOS33 [get_ports mcu_TMS]

#####                PMU define               #####
set_property IOSTANDARD LVCMOS33 [get_ports pmu_paden ]
set_property IOSTANDARD LVCMOS33 [get_ports pmu_padrst]
set_property IOSTANDARD LVCMOS33 [get_ports mcu_wakeup]

#####                gpioA define              #####
set_property IOSTANDARD LVCMOS33 [get_ports {gpioA[31]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioA[30]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioA[29]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioA[28]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioA[27]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioA[26]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioA[25]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioA[24]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioA[23]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioA[22]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioA[21]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioA[20]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioA[19]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioA[18]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioA[17]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioA[16]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioA[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioA[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioA[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioA[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioA[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioA[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioA[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioA[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioA[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioA[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioA[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioA[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioA[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioA[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioA[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioA[0]}]

#####                gpioB define              #####
set_property IOSTANDARD LVCMOS33 [get_ports {gpioB[31]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioB[30]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioB[29]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioB[28]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioB[27]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioB[26]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioB[25]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioB[24]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioB[23]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioB[22]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioB[21]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioB[20]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioB[19]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioB[18]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioB[17]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioB[16]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioB[15]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioB[14]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioB[13]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioB[12]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioB[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioB[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioB[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioB[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioB[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioB[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioB[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioB[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioB[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioB[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioB[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpioB[0]}]


#####         SPI Configurate Setting        #######
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design] 
set_property CONFIG_MODE SPIx4 [current_design] 
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]




