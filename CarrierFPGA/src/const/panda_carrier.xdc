# Encoder IO
set_property PACKAGE_PIN V11  [get_ports {Am0_pad_io[0]}];
set_property PACKAGE_PIN AA11 [get_ports {Bm0_pad_io[0]}];
set_property PACKAGE_PIN H4   [get_ports {Zm0_pad_io[0]}];
set_property PACKAGE_PIN V15  [get_ports {As0_pad_io[0]}];
set_property PACKAGE_PIN W12  [get_ports {Bs0_pad_io[0]}];
set_property PACKAGE_PIN G3   [get_ports {Zs0_pad_io[0]}];
set_property PACKAGE_PIN V13  [get_ports {Am0_pad_io[1]}];
set_property PACKAGE_PIN Y12  [get_ports {Bm0_pad_io[1]}];
set_property PACKAGE_PIN F5   [get_ports {Zm0_pad_io[1]}];
set_property PACKAGE_PIN V16  [get_ports {As0_pad_io[1]}];
set_property PACKAGE_PIN R17  [get_ports {Bs0_pad_io[1]}];
set_property PACKAGE_PIN F2   [get_ports {Zs0_pad_io[1]}];
set_property PACKAGE_PIN W11  [get_ports {Am0_pad_io[2]}];
set_property PACKAGE_PIN AB11 [get_ports {Bm0_pad_io[2]}];
set_property PACKAGE_PIN H3   [get_ports {Zm0_pad_io[2]}];
set_property PACKAGE_PIN W15  [get_ports {As0_pad_io[2]}];
set_property PACKAGE_PIN W13  [get_ports {Bs0_pad_io[2]}];
set_property PACKAGE_PIN G2   [get_ports {Zs0_pad_io[2]}];
set_property PACKAGE_PIN V14  [get_ports {Am0_pad_io[3]}];
set_property PACKAGE_PIN Y13  [get_ports {Bm0_pad_io[3]}];
set_property PACKAGE_PIN E5   [get_ports {Zm0_pad_io[3]}];
set_property PACKAGE_PIN W16  [get_ports {As0_pad_io[3]}];
set_property PACKAGE_PIN T17  [get_ports {Bs0_pad_io[3]}];
set_property PACKAGE_PIN F1   [get_ports {Zs0_pad_io[3]}];

# TTL and LVDS IO
set_property PACKAGE_PIN M2 [get_ports {lvdsin_pad_i[0]}];
set_property PACKAGE_PIN N1 [get_ports {lvdsin_pad_i[1]}];
set_property PACKAGE_PIN M1 [get_ports {lvdsout_pad_o[0]}];
set_property PACKAGE_PIN P1 [get_ports {lvdsout_pad_o[1]}];

set_property PACKAGE_PIN M4  [get_ports {ttlin_pad_i[0]}];
set_property PACKAGE_PIN J2  [get_ports {ttlin_pad_i[1]}];
set_property PACKAGE_PIN M3  [get_ports {ttlin_pad_i[2]}];
set_property PACKAGE_PIN J1  [get_ports {ttlin_pad_i[3]}];
set_property PACKAGE_PIN K7  [get_ports {ttlin_pad_i[4]}];
set_property PACKAGE_PIN J3  [get_ports {ttlin_pad_i[5]}];

set_property PACKAGE_PIN P7  [get_ports {ttlout_pad_o[0]}];
set_property PACKAGE_PIN L2  [get_ports {ttlout_pad_o[1]}];
set_property PACKAGE_PIN R7  [get_ports {ttlout_pad_o[2]}];
set_property PACKAGE_PIN L1  [get_ports {ttlout_pad_o[3]}];
set_property PACKAGE_PIN N4  [get_ports {ttlout_pad_o[4]}];
set_property PACKAGE_PIN P3  [get_ports {ttlout_pad_o[5]}];
set_property PACKAGE_PIN N3  [get_ports {ttlout_pad_o[6]}];
set_property PACKAGE_PIN P2  [get_ports {ttlout_pad_o[7]}];
set_property PACKAGE_PIN L7  [get_ports {ttlout_pad_o[8]}];
set_property PACKAGE_PIN K2  [get_ports {ttlout_pad_o[9]}];

# Slow Controller SPI Interface
set_property PACKAGE_PIN K4 [get_ports {spi_sclk_o}];
set_property PACKAGE_PIN K3 [get_ports {spi_dat_o }];
set_property PACKAGE_PIN N8 [get_ports {spi_sclk_i}];
set_property PACKAGE_PIN P8 [get_ports {spi_dat_i }];

# Set the bank voltage for IO Bank 34 to 1.8V by default.
set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 34]];
# Set the bank voltage for IO Bank 35 to 1.8V by default.
set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 35]];
# Set the bank voltage for IO Bank 13 to 3.3V by default.
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 13]];

# SPI Clock Constraints
create_generated_clock -name slowctrl_inst/slowctrl_block_inst/slowctrl_inst/sclk_prebuf -source [get_pins {ps/processing_system7_0/inst/PS7_i/FCLKCLK[0]}] -divide_by 16 [get_pins {slowctrl_inst/slowctrl_block_inst/slowctrl_inst/sclk_prebuf_reg/Q}]















