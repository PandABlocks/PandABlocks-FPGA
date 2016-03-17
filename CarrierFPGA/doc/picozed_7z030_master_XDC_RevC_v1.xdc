
#     _____
#    /     \
#   /____   \____
#  / \===\   \==/
# /___\===\___\/  AVNET ELECTRONICS MARKETING
#      \======/         www.picozed.org
#       \====/    
# ----------------------------------------------------------------------------
# 
#  Created With Avnet Constraints Generator V0.8.0 
#     Date: Friday, December 19, 2014 
#     Time: 1:57:39 PM 
# 
#  This design is the property of Avnet.  Publication of this
#  design is not authorized without written consent from Avnet.
#  
#  Please direct any questions to:
#     Avnet Technical Community Forums
#     http://picozed.org/forum
# 
#  Disclaimer:
#     Avnet, Inc. makes no warranty for the use of this code or design.
#     This code is provided  "As Is". Avnet, Inc assumes no responsibility for
#     any errors, which may appear in this code, nor does it make a commitment
#     to update the information contained herein. Avnet, Inc specifically
#     disclaims any implied warranties of fitness for a particular purpose.
#                      Copyright(c) 2014 Avnet, Inc.
#                              All rights reserved.
# 
# ----------------------------------------------------------------------------
# 
#  Notes: 
#
#  Friday, December 19, 2014
#
#     IO standards based upon Bank 34, Bank 35, and Bank 13 Vcco supply 
#     of 1.8V requires bank VCCO voltage to be set to 1.8V.
#
#     Net names are not allowed to contain hyphen characters '-' since this
#     is not a legal VHDL87 or Verilog character within an identifier.  
#     HDL net names are adjusted to contain no hyphen characters '-' but 
#     rather use underscore '_' characters.  Comment net name with the hyphen 
#     characters will remain in place since these are intended to match the 
#     schematic net names in order to better enable schematic search.
#
#     The string provided in the comment field provides the Zynq device pin 
#     mapping in the following format:
#
#     "<Zynq Pin>.<SOM Net>"
# 
# ----------------------------------------------------------------------------
 
# ----------------------------------------------------------------------------
# Expansion I/O - Bank 13 
# ----------------------------------------------------------------------------   
set_property PACKAGE_PIN AA15 [get_ports {BANK13_LVDS_0_N }];  # "AA15.BANK13_LVDS_0_N"
set_property PACKAGE_PIN AA14 [get_ports {BANK13_LVDS_0_P }];  # "AA14.BANK13_LVDS_0_P"
set_property PACKAGE_PIN Y15  [get_ports {BANK13_LVDS_1_N }];  # "Y15.BANK13_LVDS_1_N"
set_property PACKAGE_PIN Y14  [get_ports {BANK13_LVDS_1_P }];  # "Y14.BANK13_LVDS_1_P"
set_property PACKAGE_PIN Y13  [get_ports {BANK13_LVDS_10_N}];  # "Y13.BANK13_LVDS_10_N"
set_property PACKAGE_PIN Y12  [get_ports {BANK13_LVDS_10_P}];  # "Y12.BANK13_LVDS_10_P"
set_property PACKAGE_PIN W11  [get_ports {BANK13_LVDS_11_N}];  # "W11.BANK13_LVDS_11_N"
set_property PACKAGE_PIN V11  [get_ports {BANK13_LVDS_11_P}];  # "V11.BANK13_LVDS_11_P"
set_property PACKAGE_PIN V14  [get_ports {BANK13_LVDS_12_N}];  # "V14.BANK13_LVDS_12_N"
set_property PACKAGE_PIN V13  [get_ports {BANK13_LVDS_12_P}];  # "V13.BANK13_LVDS_12_P"
set_property PACKAGE_PIN W13  [get_ports {BANK13_LVDS_13_N}];  # "W13.BANK13_LVDS_13_N"
set_property PACKAGE_PIN W12  [get_ports {BANK13_LVDS_13_P}];  # "W12.BANK13_LVDS_13_P"
set_property PACKAGE_PIN T17  [get_ports {BANK13_LVDS_14_N}];  # "T17.BANK13_LVDS_14_N"
set_property PACKAGE_PIN R17  [get_ports {BANK13_LVDS_14_P}];  # "R17.BANK13_LVDS_14_P"
set_property PACKAGE_PIN W15  [get_ports {BANK13_LVDS_15_N}];  # "W15.BANK13_LVDS_15_N"
set_property PACKAGE_PIN V15  [get_ports {BANK13_LVDS_15_P}];  # "V15.BANK13_LVDS_15_P"
set_property PACKAGE_PIN W16  [get_ports {BANK13_LVDS_16_N}];  # "W16.BANK13_LVDS_16_N"
set_property PACKAGE_PIN V16  [get_ports {BANK13_LVDS_16_P}];  # "V16.BANK13_LVDS_16_P"
set_property PACKAGE_PIN V19  [get_ports {BANK13_LVDS_2_N }];  # "V19.BANK13_LVDS_2_N"
set_property PACKAGE_PIN U19  [get_ports {BANK13_LVDS_2_P }];  # "U19.BANK13_LVDS_2_P"
set_property PACKAGE_PIN W18  [get_ports {BANK13_LVDS_3_N }];  # "W18.BANK13_LVDS_3_N"
set_property PACKAGE_PIN V18  [get_ports {BANK13_LVDS_3_P }];  # "V18.BANK13_LVDS_3_P"
set_property PACKAGE_PIN AB22 [get_ports {BANK13_LVDS_4_N }];  # "AB22.BANK13_LVDS_4_N"
set_property PACKAGE_PIN AB21 [get_ports {BANK13_LVDS_4_P }];  # "AB21.BANK13_LVDS_4_P"
set_property PACKAGE_PIN AB19 [get_ports {BANK13_LVDS_5_N }];  # "AB19.BANK13_LVDS_5_N"
set_property PACKAGE_PIN AB18 [get_ports {BANK13_LVDS_5_P }];  # "AB18.BANK13_LVDS_5_P"
set_property PACKAGE_PIN AA20 [get_ports {BANK13_LVDS_6_N }];  # "AA20.BANK13_LVDS_6_N"
set_property PACKAGE_PIN AA19 [get_ports {BANK13_LVDS_6_P }];  # "AA19.BANK13_LVDS_6_P"
set_property PACKAGE_PIN Y19  [get_ports {BANK13_LVDS_7_N }];  # "Y19.BANK13_LVDS_7_N"
set_property PACKAGE_PIN Y18  [get_ports {BANK13_LVDS_7_P }];  # "Y18.BANK13_LVDS_7_P"
set_property PACKAGE_PIN AA17 [get_ports {BANK13_LVDS_8_N }];  # "AA17.BANK13_LVDS_8_N"
set_property PACKAGE_PIN AA16 [get_ports {BANK13_LVDS_8_P }];  # "AA16.BANK13_LVDS_8_P"
set_property PACKAGE_PIN AB11 [get_ports {BANK13_LVDS_9_N }];  # "AB11.BANK13_LVDS_9_N"
set_property PACKAGE_PIN AA11 [get_ports {BANK13_LVDS_9_P }];  # "AA11.BANK13_LVDS_9_P"
set_property PACKAGE_PIN T16  [get_ports {BANK13_SE_0     }];  # "T16.BANK13_SE_0"


# ----------------------------------------------------------------------------
# Expansion Connector JX1 - Bank 35 -
# Warning! Bank 35 is a High Performance Bank on the 7030 
# and will only accept 1.8V level signals
# ---------------------------------------------------------------------------- 
set_property PACKAGE_PIN H3   [get_ports {JX1_LVDS_0_N    }];  # "H3.JX1_LVDS_0_N"
set_property PACKAGE_PIN H4   [get_ports {JX1_LVDS_0_P    }];  # "H4.JX1_LVDS_0_P"
set_property PACKAGE_PIN E5   [get_ports {JX1_LVDS_1_N    }];  # "E5.JX1_LVDS_1_N"
set_property PACKAGE_PIN F5   [get_ports {JX1_LVDS_1_P    }];  # "F5.JX1_LVDS_1_P"
set_property PACKAGE_PIN C5   [get_ports {JX1_LVDS_10_N   }];  # "C5.JX1_LVDS_10_N"
set_property PACKAGE_PIN C6   [get_ports {JX1_LVDS_10_P   }];  # "C6.JX1_LVDS_10_P"
set_property PACKAGE_PIN C4   [get_ports {JX1_LVDS_11_N   }];  # "C4.JX1_LVDS_11_N"
set_property PACKAGE_PIN D5   [get_ports {JX1_LVDS_11_P   }];  # "D5.JX1_LVDS_11_P"
set_property PACKAGE_PIN B3   [get_ports {JX1_LVDS_12_N   }];  # "B3.JX1_LVDS_12_N"
set_property PACKAGE_PIN B4   [get_ports {JX1_LVDS_12_P   }];  # "B4.JX1_LVDS_12_P"
set_property PACKAGE_PIN C3   [get_ports {JX1_LVDS_13_N   }];  # "C3.JX1_LVDS_13_N"
set_property PACKAGE_PIN D3   [get_ports {JX1_LVDS_13_P   }];  # "D3.JX1_LVDS_13_P"
set_property PACKAGE_PIN C1   [get_ports {JX1_LVDS_14_N   }];  # "C1.JX1_LVDS_14_N"
set_property PACKAGE_PIN D1   [get_ports {JX1_LVDS_14_P   }];  # "D1.JX1_LVDS_14_P"
set_property PACKAGE_PIN A1   [get_ports {JX1_LVDS_15_N   }];  # "A1.JX1_LVDS_15_N"
set_property PACKAGE_PIN A2   [get_ports {JX1_LVDS_15_P   }];  # "A2.JX1_LVDS_15_P"
set_property PACKAGE_PIN D2   [get_ports {JX1_LVDS_16_N   }];  # "D2.JX1_LVDS_16_N"
set_property PACKAGE_PIN E2   [get_ports {JX1_LVDS_16_P   }];  # "E2.JX1_LVDS_16_P"
set_property PACKAGE_PIN D6   [get_ports {JX1_LVDS_17_N   }];  # "D6.JX1_LVDS_17_N"
set_property PACKAGE_PIN D7   [get_ports {JX1_LVDS_17_P   }];  # "D7.JX1_LVDS_17_P"
set_property PACKAGE_PIN E7   [get_ports {JX1_LVDS_18_N   }];  # "E7.JX1_LVDS_18_N"
set_property PACKAGE_PIN F7   [get_ports {JX1_LVDS_18_P   }];  # "F7.JX1_LVDS_18_P"
set_property PACKAGE_PIN A4   [get_ports {JX1_LVDS_19_N   }];  # "A4.JX1_LVDS_19_N"
set_property PACKAGE_PIN A5   [get_ports {JX1_LVDS_19_P   }];  # "A5.JX1_LVDS_19_P"
set_property PACKAGE_PIN G2   [get_ports {JX1_LVDS_2_N    }];  # "G2.JX1_LVDS_2_N"
set_property PACKAGE_PIN G3   [get_ports {JX1_LVDS_2_P    }];  # "G3.JX1_LVDS_2_P"
set_property PACKAGE_PIN G7   [get_ports {JX1_LVDS_20_N   }];  # "G7.JX1_LVDS_20_N"
set_property PACKAGE_PIN G8   [get_ports {JX1_LVDS_20_P   }];  # "G8.JX1_LVDS_20_P"
set_property PACKAGE_PIN A6   [get_ports {JX1_LVDS_21_N   }];  # "A6.JX1_LVDS_21_N"
set_property PACKAGE_PIN A7   [get_ports {JX1_LVDS_21_P   }];  # "A7.JX1_LVDS_21_P"
set_property PACKAGE_PIN B6   [get_ports {JX1_LVDS_22_N   }];  # "B6.JX1_LVDS_22_N"
set_property PACKAGE_PIN B7   [get_ports {JX1_LVDS_22_P   }];  # "B7.JX1_LVDS_22_P"
set_property PACKAGE_PIN B8   [get_ports {JX1_LVDS_23_N   }];  # "B8.JX1_LVDS_23_N"
set_property PACKAGE_PIN C8   [get_ports {JX1_LVDS_23_P   }];  # "C8.JX1_LVDS_23_P"
set_property PACKAGE_PIN F1   [get_ports {JX1_LVDS_3_N    }];  # "F1.JX1_LVDS_3_N"
set_property PACKAGE_PIN F2   [get_ports {JX1_LVDS_3_P    }];  # "F2.JX1_LVDS_3_P"
set_property PACKAGE_PIN F4   [get_ports {JX1_LVDS_4_N    }];  # "F4.JX1_LVDS_4_N"
set_property PACKAGE_PIN G4   [get_ports {JX1_LVDS_4_P    }];  # "G4.JX1_LVDS_4_P"
set_property PACKAGE_PIN E3   [get_ports {JX1_LVDS_5_N    }];  # "E3.JX1_LVDS_5_N"
set_property PACKAGE_PIN E4   [get_ports {JX1_LVDS_5_P    }];  # "E4.JX1_LVDS_5_P"
set_property PACKAGE_PIN F6   [get_ports {JX1_LVDS_6_N    }];  # "F6.JX1_LVDS_6_N"
set_property PACKAGE_PIN G6   [get_ports {JX1_LVDS_6_P    }];  # "G6.JX1_LVDS_6_P"
set_property PACKAGE_PIN B1   [get_ports {JX1_LVDS_7_N    }];  # "B1.JX1_LVDS_7_N"
set_property PACKAGE_PIN B2   [get_ports {JX1_LVDS_7_P    }];  # "B2.JX1_LVDS_7_P"
set_property PACKAGE_PIN D8   [get_ports {JX1_LVDS_8_N    }];  # "D8.JX1_LVDS_8_N"
set_property PACKAGE_PIN E8   [get_ports {JX1_LVDS_8_P    }];  # "E8.JX1_LVDS_8_P"
set_property PACKAGE_PIN G1   [get_ports {JX1_LVDS_9_N    }];  # "G1.JX1_LVDS_9_N"
set_property PACKAGE_PIN H1   [get_ports {JX1_LVDS_9_P    }];  # "H1.JX1_LVDS_9_P"
set_property PACKAGE_PIN H6   [get_ports {JX1_SE_0        }];  # "H6.JX1_SE_0"
set_property PACKAGE_PIN H5   [get_ports {JX1_SE_1        }];  # "H5.JX1_SE_1"


# ----------------------------------------------------------------------------
# Expansion Connector JX2 - Bank 34
# Warning! Bank 34 is a High Performance Bank on the 7030 
# and will only accept 1.8V level signals
# ---------------------------------------------------------------------------- 
set_property PACKAGE_PIN M3   [get_ports {JX2_LVDS_0_N    }];  # "M3.JX2_LVDS_0_N"
set_property PACKAGE_PIN M4   [get_ports {JX2_LVDS_0_P    }];  # "M4.JX2_LVDS_0_P"
set_property PACKAGE_PIN J1   [get_ports {JX2_LVDS_1_N    }];  # "J1.JX2_LVDS_1_N"
set_property PACKAGE_PIN J2   [get_ports {JX2_LVDS_1_P    }];  # "J2.JX2_LVDS_1_P"
set_property PACKAGE_PIN K3   [get_ports {JX2_LVDS_10_N   }];  # "K3.JX2_LVDS_10_N"
set_property PACKAGE_PIN K4   [get_ports {JX2_LVDS_10_P   }];  # "K4.JX2_LVDS_10_P"
set_property PACKAGE_PIN L4   [get_ports {JX2_LVDS_11_N   }];  # "L4.JX2_LVDS_11_N"
set_property PACKAGE_PIN L5   [get_ports {JX2_LVDS_11_P   }];  # "L5.JX2_LVDS_11_P"
set_property PACKAGE_PIN T1   [get_ports {JX2_LVDS_12_N   }];  # "T1.JX2_LVDS_12_N"
set_property PACKAGE_PIN T2   [get_ports {JX2_LVDS_12_P   }];  # "T2.JX2_LVDS_12_P"
set_property PACKAGE_PIN U1   [get_ports {JX2_LVDS_13_N   }];  # "U1.JX2_LVDS_13_N"
set_property PACKAGE_PIN U2   [get_ports {JX2_LVDS_13_P   }];  # "U2.JX2_LVDS_13_P"
set_property PACKAGE_PIN R2   [get_ports {JX2_LVDS_14_N   }];  # "R2.JX2_LVDS_14_N"
set_property PACKAGE_PIN R3   [get_ports {JX2_LVDS_14_P   }];  # "R3.JX2_LVDS_14_P"
set_property PACKAGE_PIN M6   [get_ports {JX2_LVDS_15_N   }];  # "M6.JX2_LVDS_15_N"
set_property PACKAGE_PIN L6   [get_ports {JX2_LVDS_15_P   }];  # "L6.JX2_LVDS_15_P"
set_property PACKAGE_PIN K5   [get_ports {JX2_LVDS_16_N   }];  # "K5.JX2_LVDS_16_N"
set_property PACKAGE_PIN J5   [get_ports {JX2_LVDS_16_P   }];  # "J5.JX2_LVDS_16_P"
set_property PACKAGE_PIN R4   [get_ports {JX2_LVDS_17_N   }];  # "R4.JX2_LVDS_17_N"
set_property PACKAGE_PIN R5   [get_ports {JX2_LVDS_17_P   }];  # "R5.JX2_LVDS_17_P"
set_property PACKAGE_PIN J6   [get_ports {JX2_LVDS_18_N   }];  # "J6.JX2_LVDS_18_N"
set_property PACKAGE_PIN J7   [get_ports {JX2_LVDS_18_P   }];  # "J7.JX2_LVDS_18_P"
set_property PACKAGE_PIN P5   [get_ports {JX2_LVDS_19_N   }];  # "P5.JX2_LVDS_19_N"
set_property PACKAGE_PIN P6   [get_ports {JX2_LVDS_19_P   }];  # "P6.JX2_LVDS_19_P"
set_property PACKAGE_PIN L7   [get_ports {JX2_LVDS_2_N    }];  # "L7.JX2_LVDS_2_N"
set_property PACKAGE_PIN K7   [get_ports {JX2_LVDS_2_P    }];  # "K7.JX2_LVDS_2_P"
set_property PACKAGE_PIN K8   [get_ports {JX2_LVDS_20_N   }];  # "K8.JX2_LVDS_20_N"
set_property PACKAGE_PIN J8   [get_ports {JX2_LVDS_20_P   }];  # "J8.JX2_LVDS_20_P"
set_property PACKAGE_PIN N5   [get_ports {JX2_LVDS_21_N   }];  # "N5.JX2_LVDS_21_N"
set_property PACKAGE_PIN N6   [get_ports {JX2_LVDS_21_P   }];  # "N6.JX2_LVDS_21_P"
set_property PACKAGE_PIN M7   [get_ports {JX2_LVDS_22_N   }];  # "M7.JX2_LVDS_22_N"
set_property PACKAGE_PIN M8   [get_ports {JX2_LVDS_22_P   }];  # "M8.JX2_LVDS_22_P"
set_property PACKAGE_PIN P8   [get_ports {JX2_LVDS_23_N   }];  # "P8.JX2_LVDS_23_N"
set_property PACKAGE_PIN N8   [get_ports {JX2_LVDS_23_P   }];  # "N8.JX2_LVDS_23_P"
set_property PACKAGE_PIN K2   [get_ports {JX2_LVDS_3_N    }];  # "K2.JX2_LVDS_3_N"
set_property PACKAGE_PIN J3   [get_ports {JX2_LVDS_3_P    }];  # "J3.JX2_LVDS_3_P"
set_property PACKAGE_PIN R7   [get_ports {JX2_LVDS_4_N    }];  # "R7.JX2_LVDS_4_N"
set_property PACKAGE_PIN P7   [get_ports {JX2_LVDS_4_P    }];  # "P7.JX2_LVDS_4_P"
set_property PACKAGE_PIN L1   [get_ports {JX2_LVDS_5_N    }];  # "L1.JX2_LVDS_5_N"
set_property PACKAGE_PIN L2   [get_ports {JX2_LVDS_5_P    }];  # "L2.JX2_LVDS_5_P"
set_property PACKAGE_PIN N3   [get_ports {JX2_LVDS_6_N    }];  # "N3.JX2_LVDS_6_N"
set_property PACKAGE_PIN N4   [get_ports {JX2_LVDS_6_P    }];  # "N4.JX2_LVDS_6_P"
set_property PACKAGE_PIN P2   [get_ports {JX2_LVDS_7_N    }];  # "P2.JX2_LVDS_7_N"
set_property PACKAGE_PIN P3   [get_ports {JX2_LVDS_7_P    }];  # "P3.JX2_LVDS_7_P"
set_property PACKAGE_PIN M1   [get_ports {JX2_LVDS_8_N    }];  # "M1.JX2_LVDS_8_N"
set_property PACKAGE_PIN M2   [get_ports {JX2_LVDS_8_P    }];  # "M2.JX2_LVDS_8_P"
set_property PACKAGE_PIN P1   [get_ports {JX2_LVDS_9_N    }];  # "P1.JX2_LVDS_9_N"
set_property PACKAGE_PIN N1   [get_ports {JX2_LVDS_9_P    }];  # "N1.JX2_LVDS_9_P"
set_property PACKAGE_PIN H8   [get_ports {JX2_SE_0        }];  # "H8.JX2_SE_0"
set_property PACKAGE_PIN R8   [get_ports {JX2_SE_1        }];  # "R8.JX2_SE_1"

# ----------------------------------------------------------------------------
# Expansion Connector JX3 - Bank 112
# ---------------------------------------------------------------------------- 

set_property PACKAGE_PIN V9   [get_ports {MGTREFCLKC0_N   }];  # "V9.MGTREFCLKC0_N"
set_property PACKAGE_PIN U9   [get_ports {MGTREFCLKC0_P   }];  # "U9.MGTREFCLKC0_P"
set_property PACKAGE_PIN V5   [get_ports {MGTREFCLKC1_N   }];  # "V5.MGTREFCLKC1_N"
set_property PACKAGE_PIN U5   [get_ports {MGTREFCLKC1_P   }];  # "U5.MGTREFCLKC1_P"
set_property PACKAGE_PIN AB7  [get_ports {MGTRX0_N        }];  # "AB7.MGTRX0_N"
set_property PACKAGE_PIN AA7  [get_ports {MGTRX0_P        }];  # "AA7.MGTRX0_P"
set_property PACKAGE_PIN Y8   [get_ports {MGTRX1_N        }];  # "Y8.MGTRX1_N"
set_property PACKAGE_PIN W8   [get_ports {MGTRX1_P        }];  # "W8.MGTRX1_P"
set_property PACKAGE_PIN AB9  [get_ports {MGTRX2_N        }];  # "AB9.MGTRX2_N"
set_property PACKAGE_PIN AA9  [get_ports {MGTRX2_P        }];  # "AA9.MGTRX2_P"
set_property PACKAGE_PIN Y6   [get_ports {MGTRX3_N        }];  # "Y6.MGTRX3_N"
set_property PACKAGE_PIN W6   [get_ports {MGTRX3_P        }];  # "W6.MGTRX3_P"
set_property PACKAGE_PIN AB3  [get_ports {MGTTX0_N        }];  # "AB3.MGTTX0_N"
set_property PACKAGE_PIN AA3  [get_ports {MGTTX0_P        }];  # "AA3.MGTTX0_P"
set_property PACKAGE_PIN Y4   [get_ports {MGTTX1_N        }];  # "Y4.MGTTX1_N"
set_property PACKAGE_PIN W4   [get_ports {MGTTX1_P        }];  # "W4.MGTTX1_P"
set_property PACKAGE_PIN AB5  [get_ports {MGTTX2_N        }];  # "AB5.MGTTX2_N"
set_property PACKAGE_PIN AA5  [get_ports {MGTTX2_P        }];  # "AA5.MGTTX2_P"
set_property PACKAGE_PIN Y2   [get_ports {MGTTX3_N        }];  # "Y2.MGTTX3_N"
set_property PACKAGE_PIN W2   [get_ports {MGTTX3_P        }];  # "W2.MGTTX3_P"


# ----------------------------------------------------------------------------
# IOSTANDARD Constraints
#
# Note that these IOSTANDARD constraints are applied to all IOs currently
# assigned within an I/O bank.  If these IOSTANDARD constraints are 
# evaluated prior to other PACKAGE_PIN constraints being applied, then 
# the IOSTANDARD specified will likely not be applied properly to those 
# pins.  Therefore, bank wide IOSTANDARD constraints should be placed 
# within the XDC file in a location that is evaluated AFTER all 
# PACKAGE_PIN constraints within the target bank have been evaluated.
#
# Un-comment one or more of the following IOSTANDARD constraints according to
# the bank pin assignments that are required within a design.
#
# Warning! Bank 34 and Bank 35 are a High Performance Banks on the 7030 
# and will only accept 1.8V level signals

# ---------------------------------------------------------------------------- 

# Set the bank voltage for IO Bank 34 to 1.8V by default.
set_property IOSTANDARD LVCMOS18 [get_ports –of_objects [get_iobanks 34]];

# Set the bank voltage for IO Bank 35 to 1.8V by default.
set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 35]];

# Set the bank voltage for IO Bank 13 to 1.8V by default. 
set_property IOSTANDARD LVCMOS18 [get_ports –of_objects [get_iobanks 13]];
# set_property IOSTANDARD LVCMOS25 [get_ports –of_objects [get_iobanks 13]];
# set_property IOSTANDARD LVCMOS33 [get_ports –of_objects [get_iobanks 13]];

