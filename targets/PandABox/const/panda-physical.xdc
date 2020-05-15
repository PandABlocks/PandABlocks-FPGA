# -------------------------------------------------------------------
# Encoder IO
# -------------------------------------------------------------------
set_property PACKAGE_PIN V11  [get_ports {AM0_PAD_IO[0]}];
set_property PACKAGE_PIN AA11 [get_ports {BM0_PAD_IO[0]}];
set_property PACKAGE_PIN AA14 [get_ports {ZM0_PAD_IO[0]}];

set_property PACKAGE_PIN V13  [get_ports {AM0_PAD_IO[1]}];
set_property PACKAGE_PIN Y12  [get_ports {BM0_PAD_IO[1]}];
set_property PACKAGE_PIN Y14  [get_ports {ZM0_PAD_IO[1]}];

set_property PACKAGE_PIN W11  [get_ports {AM0_PAD_IO[2]}];
set_property PACKAGE_PIN AB11 [get_ports {BM0_PAD_IO[2]}];
set_property PACKAGE_PIN AA15 [get_ports {ZM0_PAD_IO[2]}];

set_property PACKAGE_PIN V14  [get_ports {AM0_PAD_IO[3]}];
set_property PACKAGE_PIN Y13  [get_ports {BM0_PAD_IO[3]}];
set_property PACKAGE_PIN Y15  [get_ports {ZM0_PAD_IO[3]}];

set_property PACKAGE_PIN V15  [get_ports {AS0_PAD_IO[0]}];
set_property PACKAGE_PIN W12  [get_ports {BS0_PAD_IO[0]}];
set_property PACKAGE_PIN U19  [get_ports {ZS0_PAD_IO[0]}];

set_property PACKAGE_PIN V16  [get_ports {AS0_PAD_IO[1]}];
set_property PACKAGE_PIN R17  [get_ports {BS0_PAD_IO[1]}];
set_property PACKAGE_PIN V18  [get_ports {ZS0_PAD_IO[1]}];

set_property PACKAGE_PIN W15  [get_ports {AS0_PAD_IO[2]}];
set_property PACKAGE_PIN W13  [get_ports {BS0_PAD_IO[2]}];
set_property PACKAGE_PIN V19  [get_ports {ZS0_PAD_IO[2]}];

set_property PACKAGE_PIN W16  [get_ports {AS0_PAD_IO[3]}];
set_property PACKAGE_PIN T17  [get_ports {BS0_PAD_IO[3]}];
set_property PACKAGE_PIN W18  [get_ports {ZS0_PAD_IO[3]}];

# -------------------------------------------------------------------
# TTL and LVDS IO
# -------------------------------------------------------------------
set_property PACKAGE_PIN M2  [get_ports {LVDSIN_PAD_I[0]}];
set_property PACKAGE_PIN N1  [get_ports {LVDSIN_PAD_I[1]}];
set_property PACKAGE_PIN M1  [get_ports {LVDSOUT_PAD_O[0]}];
set_property PACKAGE_PIN P1  [get_ports {LVDSOUT_PAD_O[1]}];

set_property PACKAGE_PIN M4  [get_ports {TTLIN_PAD_I[0]}];
set_property PACKAGE_PIN J2  [get_ports {TTLIN_PAD_I[1]}];
set_property PACKAGE_PIN M3  [get_ports {TTLIN_PAD_I[2]}];
set_property PACKAGE_PIN J1  [get_ports {TTLIN_PAD_I[3]}];
set_property PACKAGE_PIN K7  [get_ports {TTLIN_PAD_I[4]}];
set_property PACKAGE_PIN J3  [get_ports {TTLIN_PAD_I[5]}];

set_property PACKAGE_PIN P7  [get_ports {TTLOUT_PAD_O[0]}];
set_property PACKAGE_PIN L2  [get_ports {TTLOUT_PAD_O[1]}];
set_property PACKAGE_PIN R7  [get_ports {TTLOUT_PAD_O[2]}];
set_property PACKAGE_PIN L1  [get_ports {TTLOUT_PAD_O[3]}];
set_property PACKAGE_PIN N4  [get_ports {TTLOUT_PAD_O[4]}];
set_property PACKAGE_PIN P3  [get_ports {TTLOUT_PAD_O[5]}];
set_property PACKAGE_PIN N3  [get_ports {TTLOUT_PAD_O[6]}];
set_property PACKAGE_PIN P2  [get_ports {TTLOUT_PAD_O[7]}];
set_property PACKAGE_PIN L7  [get_ports {TTLOUT_PAD_O[8]}];
set_property PACKAGE_PIN K2  [get_ports {TTLOUT_PAD_O[9]}];

# -------------------------------------------------------------------
# External Clock Constraints
# -------------------------------------------------------------------
set_property PACKAGE_PIN Y18  [get_ports {EXTCLK_P}];
set_property PACKAGE_PIN Y19  [get_ports {EXTCLK_N}];

# -------------------------------------------------------------------
# Slow Controller SPI Interface)
# -------------------------------------------------------------------
set_property PACKAGE_PIN K4 [get_ports {SPI_SCLK_O}];
set_property PACKAGE_PIN K3 [get_ports {SPI_DAT_I }];
set_property PACKAGE_PIN N8 [get_ports {SPI_SCLK_I}];
set_property PACKAGE_PIN P8 [get_ports {SPI_DAT_O }];

# -------------------------------------------------------------------
# FMC Differential Pins
# -------------------------------------------------------------------
set_property PACKAGE_PIN R8   [get_ports {FMC_PRSNT     }];
set_property PACKAGE_PIN H3   [get_ports {FMC_LA_N[3]   }];
set_property PACKAGE_PIN H4   [get_ports {FMC_LA_P[3]   }];
set_property PACKAGE_PIN G2   [get_ports {FMC_LA_N[8]   }];
set_property PACKAGE_PIN G3   [get_ports {FMC_LA_P[8]   }];
set_property PACKAGE_PIN F4   [get_ports {FMC_LA_N[12]  }];
set_property PACKAGE_PIN G4   [get_ports {FMC_LA_P[12]  }];
set_property PACKAGE_PIN F6   [get_ports {FMC_LA_N[16]  }];
set_property PACKAGE_PIN G6   [get_ports {FMC_LA_P[16]  }];
set_property PACKAGE_PIN D8   [get_ports {FMC_LA_N[20]  }];
set_property PACKAGE_PIN E8   [get_ports {FMC_LA_P[20]  }];
set_property PACKAGE_PIN C5   [get_ports {FMC_LA_N[22]  }];
set_property PACKAGE_PIN C6   [get_ports {FMC_LA_P[22]  }];
set_property PACKAGE_PIN C1   [get_ports {FMC_LA_N[1]   }];
set_property PACKAGE_PIN D1   [get_ports {FMC_LA_P[1]   }];
set_property PACKAGE_PIN D2   [get_ports {FMC_LA_N[25]  }];
set_property PACKAGE_PIN E2   [get_ports {FMC_LA_P[25]  }];
set_property PACKAGE_PIN E7   [get_ports {FMC_LA_N[29]  }];
set_property PACKAGE_PIN F7   [get_ports {FMC_LA_P[29]  }];
set_property PACKAGE_PIN G7   [get_ports {FMC_LA_N[31]  }];
set_property PACKAGE_PIN G8   [get_ports {FMC_LA_P[31]  }];
set_property PACKAGE_PIN B6   [get_ports {FMC_LA_N[33]  }];
set_property PACKAGE_PIN B7   [get_ports {FMC_LA_P[33]  }];
set_property PACKAGE_PIN E5   [get_ports {FMC_LA_N[2]   }];
set_property PACKAGE_PIN F5   [get_ports {FMC_LA_P[2]   }];
set_property PACKAGE_PIN F1   [get_ports {FMC_LA_N[4]   }];
set_property PACKAGE_PIN F2   [get_ports {FMC_LA_P[4]   }];
set_property PACKAGE_PIN E3   [get_ports {FMC_LA_N[7]   }];
set_property PACKAGE_PIN E4   [get_ports {FMC_LA_P[7]   }];
set_property PACKAGE_PIN B1   [get_ports {FMC_LA_N[11]  }];
set_property PACKAGE_PIN B2   [get_ports {FMC_LA_P[11]  }];
set_property PACKAGE_PIN G1   [get_ports {FMC_LA_N[15]  }];
set_property PACKAGE_PIN H1   [get_ports {FMC_LA_P[15]  }];
set_property PACKAGE_PIN C4   [get_ports {FMC_LA_N[19]  }];
set_property PACKAGE_PIN D5   [get_ports {FMC_LA_P[19]  }];
set_property PACKAGE_PIN C3   [get_ports {FMC_LA_N[0]   }];
set_property PACKAGE_PIN D3   [get_ports {FMC_LA_P[0]   }];
set_property PACKAGE_PIN A1   [get_ports {FMC_LA_N[21]  }];
set_property PACKAGE_PIN A2   [get_ports {FMC_LA_P[21]  }];
set_property PACKAGE_PIN D6   [get_ports {FMC_LA_N[24]  }];
set_property PACKAGE_PIN D7   [get_ports {FMC_LA_P[24]  }];
set_property PACKAGE_PIN A4   [get_ports {FMC_LA_N[28]  }];
set_property PACKAGE_PIN A5   [get_ports {FMC_LA_P[28]  }];
set_property PACKAGE_PIN A6   [get_ports {FMC_LA_N[30]  }];
set_property PACKAGE_PIN A7   [get_ports {FMC_LA_P[30]  }];
set_property PACKAGE_PIN B8   [get_ports {FMC_LA_N[32]  }];
set_property PACKAGE_PIN C8   [get_ports {FMC_LA_P[32]  }];
set_property PACKAGE_PIN R2   [get_ports {FMC_LA_N[5]   }];
set_property PACKAGE_PIN R3   [get_ports {FMC_LA_P[5]   }];
set_property PACKAGE_PIN K5   [get_ports {FMC_LA_N[9]   }];
set_property PACKAGE_PIN J5   [get_ports {FMC_LA_P[9]   }];
set_property PACKAGE_PIN J6   [get_ports {FMC_LA_N[13]  }];
set_property PACKAGE_PIN J7   [get_ports {FMC_LA_P[13]  }];
set_property PACKAGE_PIN K8   [get_ports {FMC_LA_N[23]  }];
set_property PACKAGE_PIN J8   [get_ports {FMC_LA_P[23]  }];
set_property PACKAGE_PIN M7   [get_ports {FMC_LA_N[26]  }];
set_property PACKAGE_PIN M8   [get_ports {FMC_LA_P[26]  }];
set_property PACKAGE_PIN L4   [get_ports {FMC_LA_N[17]  }];
set_property PACKAGE_PIN L5   [get_ports {FMC_LA_P[17]  }];
set_property PACKAGE_PIN U1   [get_ports {FMC_LA_N[18]  }];
set_property PACKAGE_PIN U2   [get_ports {FMC_LA_P[18]  }];
set_property PACKAGE_PIN M6   [get_ports {FMC_LA_N[6]   }];
set_property PACKAGE_PIN L6   [get_ports {FMC_LA_P[6]   }];
set_property PACKAGE_PIN R4   [get_ports {FMC_LA_N[10]  }];
set_property PACKAGE_PIN R5   [get_ports {FMC_LA_P[10]  }];
set_property PACKAGE_PIN P5   [get_ports {FMC_LA_N[14]  }];
set_property PACKAGE_PIN P6   [get_ports {FMC_LA_P[14]  }];
set_property PACKAGE_PIN N5   [get_ports {FMC_LA_N[27]  }];
set_property PACKAGE_PIN N6   [get_ports {FMC_LA_P[27]  }];
set_property PACKAGE_PIN T1   [get_ports {FMC_CLK0_M2C_N}];
set_property PACKAGE_PIN T2   [get_ports {FMC_CLK0_M2C_P}];
set_property PACKAGE_PIN B3   [get_ports {FMC_CLK1_M2C_N}];
set_property PACKAGE_PIN B4   [get_ports {FMC_CLK1_M2C_P}];

# -------------------------------------------------------------------
# MGT REF CLKS - Bank 112
# -------------------------------------------------------------------
set_property PACKAGE_PIN U9 [get_ports GTXCLK0_P]
set_property PACKAGE_PIN V9 [get_ports GTXCLK0_N]
set_property PACKAGE_PIN U5 [get_ports GTXCLK1_P]
set_property PACKAGE_PIN V5 [get_ports GTXCLK1_N]

# -------------------------------------------------------------------
# SFP TX Enable (always)
# -------------------------------------------------------------------
set_property PACKAGE_PIN AB21   [get_ports {SFP_TxDis[0]  }];   #SFP1_IO1
set_property PACKAGE_PIN AB22   [get_ports {SFP_TxDis[1]  }];   #SFP2_IO1
set_property PACKAGE_PIN AB18   [get_ports {SFP_LOS[0]  }];   #SFP1_IO2
set_property PACKAGE_PIN AB19   [get_ports {SFP_LOS[1]  }];   #SFP2_IO2


# -------------------------------------------------------------------
# IOSTANDARD VCCOIO Constraints
# -------------------------------------------------------------------
# Set the bank voltage for IO Bank 34 to 1.8V by default.
set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 34]];
# Set the bank voltage for IO Bank 35 to 1.8V by default.
set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 35]];
# Set the bank voltage for IO Bank 13 to 3.3V by default.
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 13]];

# -------------------------------------------------------------------
# Override Differential Pairs' IOSTANDARD
# -------------------------------------------------------------------
set_property IOSTANDARD LVDS_25 [get_ports EXTCLK_P]

# -------------------------------------------------------------------
# Pack fixed carrier board IO into IOBs (modules not included)
# -------------------------------------------------------------------
#set inputs [filter [all_inputs] {NAME =~ *TTL* || NAME =~ *LVDS* || NAME =~ *SPI* }]
#set outputs [filter [all_outputs] {NAME =~ *TTL* || NAME =~ *LVDS* || NAME =~ *SPI* }]
#set bidirs [filter [all_outputs] {NAME =~ *PAD_IO*}]

#set_property iob true $inputs
#set_property iob true $outputs
#set_property iob true $bidirs

# -------------------------------------------------------------------
# Enable on-chip pulldown for floating inputs
# -------------------------------------------------------------------
#set_property PULLTYPE PULLDOWN [get_ports TTLIN_PAD_I[*]]
#set_property PULLTYPE PULLDOWN [get_ports LVDSIN_PAD_I[*]]

set FMC_GTX_LOC  GTXE2_CHANNEL_X0Y0
set SFP1_GTX_LOC GTXE2_CHANNEL_X0Y3
set SFP2_GTX_LOC GTXE2_CHANNEL_X0Y2
set SFP3_GTX_LOC GTXE2_CHANNEL_X0Y1

