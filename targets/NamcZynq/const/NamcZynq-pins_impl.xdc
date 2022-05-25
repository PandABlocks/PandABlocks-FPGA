# -------------------------------------------------------------------
# Encoder IO
# -------------------------------------------------------------------

# -------------------------------------------------------------------
# TTL and LVDS IO
# -------------------------------------------------------------------

# -------------------------------------------------------------------
# External Clock Constraints
# -------------------------------------------------------------------

# -------------------------------------------------------------------
# Slow Controller SPI Interface)
# -------------------------------------------------------------------

# -------------------------------------------------------------------
# FMC Differential Pins
# -------------------------------------------------------------------
# FMC-ADC-100M-14b4Cha board
# ----------------------------
#     | Pin    Signal        | FPGA Pin name       | Bank | I/O   | FMC-ADC-100M-14b4Cha
# -------------------------- |---------------------|----------------------------------------------------
#  1  | AG16   FMC_LA_N[0]   | IO_L13N_T2_MRCC_10  |  10  | IN    | ADC_DCO_P     (inverted on FMC schematic)
#  2  | AG17   FMC_LA_P[0]   | IO_L13P_T2_MRCC_10  |  10  | IN    | ADC_DCO_N     (inverted on FMC schematic)
#  3  | AG14   FMC_LA_N[1]   | IO_L12N_T1_MRCC_10  |  10  | IN    | ADC_FR_P      (inverted on FMC schematic)
#  4  | AF14   FMC_LA_P[1]   | IO_L12P_T1_MRCC_10  |  10  | IN    | ADC_FR_N      (inverted on FMC schematic)
#  5  | AK15   FMC_LA_N[14]  | IO_L5N_T0_10        |  10  | IN    | ADC_OUT1A_N
#  6  | AJ15   FMC_LA_P[14]  | IO_L5P_T0_10        |  10  | IN    | ADC_OUT1A_P
#  7  | AJ18   FMC_LA_N[15]  | IO_L2N_T0_10        |  10  | IN    | ADC_OUT1B_N
#  8  | AH18   FMC_LA_P[15]  | IO_L2P_T0_10        |  10  | IN    | ADC_OUT1B_P
#  9  | AK16   FMC_LA_N[16]  | IO_L4N_T0_10        |  10  | IN    | ADC_OUT2A_N
#  10 | AJ16   FMC_LA_P[16]  | IO_L4P_T0_10        |  10  | IN    | ADC_OUT2A_P
#  11 | AJ13   FMC_LA_N[13]  | IO_L3N_T0_DQS_10    |  10  | IN    | ADC_OUT2B_N
#  12 | AJ14   FMC_LA_P[13]  | IO_L3P_T0_DQS_10    |  10  | IN    | ADC_OUT2B_P
#  13 | AH12   FMC_LA_N[10]  | IO_L10N_T1_10       |  10  | IN    | ADC_OUT3A_N
#  14 | AG12   FMC_LA_P[10]  | IO_L10P_T1_10       |  10  | IN    | ADC_OUT3A_P
#  15 | AH13   FMC_LA_N[9]   | IO_L8N_T1_10        |  10  | IN    | ADC_OUT3B_N
#  16 | AH14   FMC_LA_P[9]   | IO_L8P_T1_10        |  10  | IN    | ADC_OUT3B_P
#  17 | AE17   FMC_LA_N[7]   | IO_L17N_T2_10       |  10  | IN    | ADC_OUT4A_N
#  18 | AE18   FMC_LA_P[7]   | IO_L17P_T2_10       |  10  | IN    | ADC_OUT4A_P
#  19 | AE15   FMC_LA_N[5]   | IO_L16N_T2_10       |  10  | IN    | ADC_OUT4B_N
#  20 | AE16   FMC_LA_P[5]   | IO_L16P_T2_10       |  10  | IN    | ADC_OUT4B_P
#  21 | AA24   FMC_LA_P[30]  | IO_L22P_T3_11       |  11  | OUT   | ADC_CS_N
#  22 | AB24   FMC_LA_N[30]  | IO_L22N_T3_11       |  11  | OUT   | DAC_CLR_N
#  23 | W21    FMC_LA_P[32]  | IO_L20P_T3_11       |  11  | OUT   | DAC1_CS_N
#  24 | Y21    FMC_LA_N[32]  | IO_L20N_T3_11       |  11  | OUT   | DAC2_CS_N
#  25 | Y22    FMC_LA_P[33]  | IO_L21P_T3_DQS_11   |  11  | OUT   | DAC3_CS_N
#  26 | Y23    FMC_LA_N[33]  | IO_L21N_T3_DQS_11   |  11  | OUT   | DAC4_CS_N
#  27 | AC23   FMC_LA_N[29]  | IO_L24N_T3_11       |  11  | BIDIR | DS18B20_DQ
#  28 | AD24   FMC_LA_N[28]  | IO_L7N_T1_11        |  11  | OUT   | LED_ACQ
#  29 | AC24   FMC_LA_P[28]  | IO_L7P_T1_11        |  11  | OUT   | LED_TRIG
#  30 | AD13   FMC_LA_N[6]   | IO_L9N_T1_DQS_10    |  10  | OUT   | SI570_OE
#  31 | AF22   FMC_LA_N[18]  | IO_L12N_T1_MRCC_11  |  11  | BIDIR | SI570_SCLK
#  32 | AE22   FMC_LA_P[18]  | IO_L12P_T1_MRCC_11  |  11  | BIDIR | SI570_SDA
#  33 | AG24   FMC_LA_P[25]  | IO_L8P_T1_11        |  11  | IN    | SPI_ADC_SDO
#  34 | AA23   FMC_LA_N[31]  | IO_L23N_T3_11       |  11  | OUT   | SPI_DIN
#  35 | AA22   FMC_LA_P[31]  | IO_L23P_T3_11       |  11  | OUT   | SPI_SCK
#  36 | AJ23   FMC_LA_P[26]  | IO_L4P_T0_11        |  11  | OUT   | SW1 CH 1
#  37 | AK17   FMC_LA_P[20]  | IO_L16P_T2_11       |  11  | OUT   | SW1 CH 2
#  38 | AE12   FMC_LA_P[8]   | IO_L7P_T1_10        |  10  | OUT   | SW1 CH 3
#  39 | AA15   FMC_LA_P[2]   | IO_L20P_T3_10       |  10  | OUT   | SW1 CH 4
#  40 | AJ24   FMC_LA_N[26]  | IO_L4N_T0_11        |  11  | OUT   | SW2 CH 1
#  41 | AJ19   FMC_LA_N[19]  | IO_L17N_T2_11       |  11  | OUT   | SW2 CH 2
#  42 | AF12   FMC_LA_N[8]   | IO_L7N_T1_10        |  10  | OUT   | SW2 CH 3
#  43 | AA14   FMC_LA_N[2]   | IO_L20N_T3_10       |  10  | OUT   | SW2 CH 4
#  44 | AH24   FMC_LA_N[27]  | IO_L5N_T0_11        |  11  | OUT   | SW3 CH 1
#  45 | AF18   FMC_LA_P[22]  | IO_L15P_T2_DQS_10   |  10  | OUT   | SW3 CH 2
#  46 | AK13   FMC_LA_P[12]  | IO_L1P_T0_10        |  10  | OUT   | SW3 CH 3
#  47 | AD16   FMC_LA_P[3]   | IO_L18P_T2_10       |  10  | OUT   | SW3 CH 4
#  48 | AG25   FMC_LA_N[25]  | IO_L8N_T1_11        |  11  | OUT   | SW4 CH 1
#  49 | AF17   FMC_LA_N[22]  | IO_L15N_T2_DQS_10   |  10  | OUT   | SW4 CH 2
#  50 | AK12   FMC_LA_N[12]  | IO_L1N_T0_10        |  10  | OUT   | SW4 CH 3
#  51 | AD15   FMC_LA_N[3]   | IO_L18N_T2_10       |  10  | OUT   | SW4 CH 4
#  52 | AF23   FMC_LA_P[24]  | IO_L9P_T1_DQS_11    |  11  | OUT   | SW5 CH 1
#  53 | AD21   FMC_LA_P[21]  | IO_L10P_T1_11       |  11  | OUT   | SW5 CH 2
#  54 | AF19   FMC_LA_P[11]  | IO_L18P_T2_11       |  11  | OUT   | SW5 CH 3
#  55 | AB12   FMC_LA_P[4]   | IO_L21P_T3_DQS_10   |  10  | OUT   | SW5 CH 4
#  56 | AF24   FMC_LA_N[24]  | IO_L9N_T1_DQS_11    |  11  | OUT   | SW6 CH 1
#  57 | AH23   FMC_LA_P[27]  | IO_L5P_T0_11        |  11  | OUT   | SW6 CH 2
#  58 | AG19   FMC_LA_N[11]  | IO_L18N_T2_11       |  11  | OUT   | SW6 CH 3
#  59 | AD14   FMC_LA_P[6]   | IO_L9P_T1_DQS_10    |  10  | OUT   | SW6 CH 4
#  60 | AC22   FMC_LA_P[29]  | IO_L24P_T3_11       |  11  | OUT   | SW7 CH 1
#  61 | AE21   FMC_LA_N[21]  | IO_L10N_T1_11       |  11  | OUT   | SW7 CH 2
#  62 | AK18   FMC_LA_N[20]  | IO_L16N_T2_11       |  11  | OUT   | SW7 CH 3
#  63 | AC12   FMC_LA_N[4]   | IO_L21N_T3_DQS_10   |  10  | OUT   | SW7 CH 4
#  64 | AH21   FMC_LA_N[17]  | IO_L13N_T2_MRCC_11  |  11  | IN    | TRIGGER_IN_N
#  65 | AG21   FMC_LA_P[17]  | IO_L13P_T2_MRCC_11  |  11  | IN    | TRIGGER_IN_P
#  66 | AH19   FMC_LA_P[19]  | IO_L17P_T2_11       |  11  |
#  67 | AJ20   FMC_LA_P[23]  | IO_L15P_T2_DQS_11   |  11  |
#  68 | AK20   FMC_LA_N[23]  | IO_L15N_T2_DQS_11   |  11  |


# -----------------------------------------------------------
# FMC_LA_P/N[33 downto 0] 34 pairs
# -----------------------------------------------------------
set_property PACKAGE_PIN AG16   [get_ports {FMC_LA_N[0]   }];
set_property PACKAGE_PIN AG17   [get_ports {FMC_LA_P[0]   }];
set_property PACKAGE_PIN AG14   [get_ports {FMC_LA_N[1]   }];
set_property PACKAGE_PIN AF14   [get_ports {FMC_LA_P[1]   }];
set_property PACKAGE_PIN AA14   [get_ports {FMC_LA_N[2]   }];
set_property PACKAGE_PIN AA15   [get_ports {FMC_LA_P[2]   }];
set_property PACKAGE_PIN AD15   [get_ports {FMC_LA_N[3]   }];
set_property PACKAGE_PIN AD16   [get_ports {FMC_LA_P[3]   }];
set_property PACKAGE_PIN AC12   [get_ports {FMC_LA_N[4]   }];
set_property PACKAGE_PIN AB12   [get_ports {FMC_LA_P[4]   }];
set_property PACKAGE_PIN AE15   [get_ports {FMC_LA_N[5]   }];
set_property PACKAGE_PIN AE16   [get_ports {FMC_LA_P[5]   }];
set_property PACKAGE_PIN AD13   [get_ports {FMC_LA_N[6]   }];
set_property PACKAGE_PIN AD14   [get_ports {FMC_LA_P[6]   }];
set_property PACKAGE_PIN AE17   [get_ports {FMC_LA_N[7]   }];
set_property PACKAGE_PIN AE18   [get_ports {FMC_LA_P[7]   }];
set_property PACKAGE_PIN AF12   [get_ports {FMC_LA_N[8]   }];
set_property PACKAGE_PIN AE12   [get_ports {FMC_LA_P[8]   }];
set_property PACKAGE_PIN AH13   [get_ports {FMC_LA_N[9]   }];
set_property PACKAGE_PIN AH14   [get_ports {FMC_LA_P[9]   }];
set_property PACKAGE_PIN AH12   [get_ports {FMC_LA_N[10]  }];
set_property PACKAGE_PIN AG12   [get_ports {FMC_LA_P[10]  }];
set_property PACKAGE_PIN AG19   [get_ports {FMC_LA_N[11]  }];
set_property PACKAGE_PIN AF19   [get_ports {FMC_LA_P[11]  }];
set_property PACKAGE_PIN AK12   [get_ports {FMC_LA_N[12]  }];
set_property PACKAGE_PIN AK13   [get_ports {FMC_LA_P[12]  }];
set_property PACKAGE_PIN AJ13   [get_ports {FMC_LA_N[13]  }];
set_property PACKAGE_PIN AJ14   [get_ports {FMC_LA_P[13]  }];
set_property PACKAGE_PIN AK15   [get_ports {FMC_LA_N[14]  }];
set_property PACKAGE_PIN AJ15   [get_ports {FMC_LA_P[14]  }];
set_property PACKAGE_PIN AJ18   [get_ports {FMC_LA_N[15]  }];
set_property PACKAGE_PIN AH18   [get_ports {FMC_LA_P[15]  }];
set_property PACKAGE_PIN AK16   [get_ports {FMC_LA_N[16]  }];
set_property PACKAGE_PIN AJ16   [get_ports {FMC_LA_P[16]  }];
set_property PACKAGE_PIN AH21   [get_ports {FMC_LA_N[17]  }];
set_property PACKAGE_PIN AG21   [get_ports {FMC_LA_P[17]  }];
set_property PACKAGE_PIN AF22   [get_ports {FMC_LA_N[18]  }];
set_property PACKAGE_PIN AE22   [get_ports {FMC_LA_P[18]  }];
set_property PACKAGE_PIN AJ19   [get_ports {FMC_LA_N[19]  }];
set_property PACKAGE_PIN AH19   [get_ports {FMC_LA_P[19]  }];
set_property PACKAGE_PIN AK18   [get_ports {FMC_LA_N[20]  }];
set_property PACKAGE_PIN AK17   [get_ports {FMC_LA_P[20]  }];
set_property PACKAGE_PIN AE21   [get_ports {FMC_LA_N[21]  }];
set_property PACKAGE_PIN AD21   [get_ports {FMC_LA_P[21]  }];
set_property PACKAGE_PIN AF17   [get_ports {FMC_LA_N[22]  }];
set_property PACKAGE_PIN AF18   [get_ports {FMC_LA_P[22]  }];
set_property PACKAGE_PIN AK20   [get_ports {FMC_LA_N[23]  }];
set_property PACKAGE_PIN AJ20   [get_ports {FMC_LA_P[23]  }];
set_property PACKAGE_PIN AF24   [get_ports {FMC_LA_N[24]  }];
set_property PACKAGE_PIN AF23   [get_ports {FMC_LA_P[24]  }];
set_property PACKAGE_PIN AG25   [get_ports {FMC_LA_N[25]  }];
set_property PACKAGE_PIN AG24   [get_ports {FMC_LA_P[25]  }];
set_property PACKAGE_PIN AJ24   [get_ports {FMC_LA_N[26]  }];
set_property PACKAGE_PIN AJ23   [get_ports {FMC_LA_P[26]  }];
set_property PACKAGE_PIN AH24   [get_ports {FMC_LA_N[27]  }];
set_property PACKAGE_PIN AH23   [get_ports {FMC_LA_P[27]  }];
set_property PACKAGE_PIN AD24   [get_ports {FMC_LA_N[28]  }];
set_property PACKAGE_PIN AC24   [get_ports {FMC_LA_P[28]  }];
set_property PACKAGE_PIN AC23   [get_ports {FMC_LA_N[29]  }];
set_property PACKAGE_PIN AC22   [get_ports {FMC_LA_P[29]  }];
set_property PACKAGE_PIN AB24   [get_ports {FMC_LA_N[30]  }];
set_property PACKAGE_PIN AA24   [get_ports {FMC_LA_P[30]  }];
set_property PACKAGE_PIN AA23   [get_ports {FMC_LA_N[31]  }];
set_property PACKAGE_PIN AA22   [get_ports {FMC_LA_P[31]  }];
set_property PACKAGE_PIN Y21    [get_ports {FMC_LA_N[32]  }];
set_property PACKAGE_PIN W21    [get_ports {FMC_LA_P[32]  }];
set_property PACKAGE_PIN Y23    [get_ports {FMC_LA_N[33]  }];
set_property PACKAGE_PIN Y22    [get_ports {FMC_LA_P[33]  }];


# -----------------------------------------------------------
# FMC_HA_P/N[21 downto 0] (22 pairs)
# -----------------------------------------------------------
set_property PACKAGE_PIN AD28   [get_ports {FMC_HA_N[0]   }];
set_property PACKAGE_PIN AC28   [get_ports {FMC_HA_P[0]   }];
set_property PACKAGE_PIN AC27   [get_ports {FMC_HA_N[1]   }];
set_property PACKAGE_PIN AB27   [get_ports {FMC_HA_P[1]   }];
set_property PACKAGE_PIN AA28   [get_ports {FMC_HA_N[2]   }];
set_property PACKAGE_PIN AA27   [get_ports {FMC_HA_P[2]   }];
set_property PACKAGE_PIN AA30   [get_ports {FMC_HA_N[3]   }];
set_property PACKAGE_PIN Y30    [get_ports {FMC_HA_P[3]   }];
set_property PACKAGE_PIN AA29   [get_ports {FMC_HA_N[4]   }];
set_property PACKAGE_PIN Y28    [get_ports {FMC_HA_P[4]   }];
set_property PACKAGE_PIN Y27    [get_ports {FMC_HA_N[5]   }];
set_property PACKAGE_PIN Y26    [get_ports {FMC_HA_P[5]   }];
set_property PACKAGE_PIN AK23   [get_ports {FMC_HA_N[6]   }];
set_property PACKAGE_PIN AK22   [get_ports {FMC_HA_P[6]   }];
set_property PACKAGE_PIN AD26   [get_ports {FMC_HA_N[7]   }];
set_property PACKAGE_PIN AC26   [get_ports {FMC_HA_P[7]   }];
set_property PACKAGE_PIN AD29   [get_ports {FMC_HA_N[8]   }];
set_property PACKAGE_PIN AC29   [get_ports {FMC_HA_P[8]   }];
set_property PACKAGE_PIN AB30   [get_ports {FMC_HA_N[9]   }];
set_property PACKAGE_PIN AB29   [get_ports {FMC_HA_P[9]   }];
set_property PACKAGE_PIN AH27   [get_ports {FMC_HA_N[10]  }];
set_property PACKAGE_PIN AH26   [get_ports {FMC_HA_P[10]  }];
set_property PACKAGE_PIN AK26   [get_ports {FMC_HA_N[11]  }];
set_property PACKAGE_PIN AJ26   [get_ports {FMC_HA_P[11]  }];
set_property PACKAGE_PIN AF25   [get_ports {FMC_HA_N[12]  }];
set_property PACKAGE_PIN AE25   [get_ports {FMC_HA_P[12]  }];
set_property PACKAGE_PIN AE26   [get_ports {FMC_HA_N[13]  }];
set_property PACKAGE_PIN AD25   [get_ports {FMC_HA_P[13]  }];
set_property PACKAGE_PIN AG27   [get_ports {FMC_HA_N[14]  }];
set_property PACKAGE_PIN AG26   [get_ports {FMC_HA_P[14]  }];
set_property PACKAGE_PIN AJ29   [get_ports {FMC_HA_N[15]  }];
set_property PACKAGE_PIN AJ28   [get_ports {FMC_HA_P[15]  }];
set_property PACKAGE_PIN AK25   [get_ports {FMC_HA_N[16]  }];
set_property PACKAGE_PIN AJ25   [get_ports {FMC_HA_P[16]  }];
set_property PACKAGE_PIN AF28   [get_ports {FMC_HA_N[17]  }];
set_property PACKAGE_PIN AE28   [get_ports {FMC_HA_P[17]  }];
set_property PACKAGE_PIN AG29   [get_ports {FMC_HA_N[18]  }];
set_property PACKAGE_PIN AF29   [get_ports {FMC_HA_P[18]  }];
set_property PACKAGE_PIN AK30   [get_ports {FMC_HA_N[19]  }];
set_property PACKAGE_PIN AJ30   [get_ports {FMC_HA_P[19]  }];
set_property PACKAGE_PIN AK28   [get_ports {FMC_HA_N[20]  }];
set_property PACKAGE_PIN AK27   [get_ports {FMC_HA_P[20]  }];
set_property PACKAGE_PIN AG30   [get_ports {FMC_HA_N[21]  }];
set_property PACKAGE_PIN AF30   [get_ports {FMC_HA_P[21]  }];


# -----------------------------------------------------------
# FMC_HB_P/N[21 downto 0] (22 pairs)
# -----------------------------------------------------------
# Reference : NAMC-ZYNQ-FMC Technical Reference Manual v1.2
# -----------------------------------------------------------
set_property PACKAGE_PIN U27    [get_ports {FMC_HB_N[0]   }];
set_property PACKAGE_PIN U26    [get_ports {FMC_HB_P[0]   }];
set_property PACKAGE_PIN W26    [get_ports {FMC_HB_N[1]   }];
set_property PACKAGE_PIN W25    [get_ports {FMC_HB_P[1]   }];
set_property PACKAGE_PIN V24    [get_ports {FMC_HB_N[2]   }];
set_property PACKAGE_PIN U24    [get_ports {FMC_HB_P[2]   }];
set_property PACKAGE_PIN W24    [get_ports {FMC_HB_N[3]   }];
set_property PACKAGE_PIN V23    [get_ports {FMC_HB_P[3]   }];
set_property PACKAGE_PIN W28    [get_ports {FMC_HB_N[4]   }];
set_property PACKAGE_PIN V27    [get_ports {FMC_HB_P[4]   }];
set_property PACKAGE_PIN V26    [get_ports {FMC_HB_N[5]   }];
set_property PACKAGE_PIN U25    [get_ports {FMC_HB_P[5]   }];
set_property PACKAGE_PIN R26    [get_ports {FMC_HB_N[6]   }];
set_property PACKAGE_PIN R25    [get_ports {FMC_HB_P[6]   }];
set_property PACKAGE_PIN V29    [get_ports {FMC_HB_N[7]   }];
set_property PACKAGE_PIN V28    [get_ports {FMC_HB_P[7]   }];
set_property PACKAGE_PIN U30    [get_ports {FMC_HB_N[8]   }];
set_property PACKAGE_PIN T30    [get_ports {FMC_HB_P[8]   }];
set_property PACKAGE_PIN W30    [get_ports {FMC_HB_N[9]   }];
set_property PACKAGE_PIN W29    [get_ports {FMC_HB_P[9]   }];
set_property PACKAGE_PIN V22    [get_ports {FMC_HB_N[10]  }];
set_property PACKAGE_PIN U22    [get_ports {FMC_HB_P[10]  }];
set_property PACKAGE_PIN U29    [get_ports {FMC_HB_N[11]  }];
set_property PACKAGE_PIN T29    [get_ports {FMC_HB_P[11]  }];
set_property PACKAGE_PIN T23    [get_ports {FMC_HB_N[12]  }];
set_property PACKAGE_PIN T22    [get_ports {FMC_HB_P[12]  }];
set_property PACKAGE_PIN T25    [get_ports {FMC_HB_N[13]  }];
set_property PACKAGE_PIN T24    [get_ports {FMC_HB_P[13]  }];
set_property PACKAGE_PIN N27    [get_ports {FMC_HB_N[14]  }];
set_property PACKAGE_PIN N26    [get_ports {FMC_HB_P[14]  }];
set_property PACKAGE_PIN R23    [get_ports {FMC_HB_N[15]  }];
set_property PACKAGE_PIN R22    [get_ports {FMC_HB_P[15]  }];
set_property PACKAGE_PIN P26    [get_ports {FMC_HB_N[16]  }];
set_property PACKAGE_PIN P25    [get_ports {FMC_HB_P[16]  }];
set_property PACKAGE_PIN T27    [get_ports {FMC_HB_N[17]  }];
set_property PACKAGE_PIN R27    [get_ports {FMC_HB_P[17]  }];
set_property PACKAGE_PIN R30    [get_ports {FMC_HB_N[18]  }];
set_property PACKAGE_PIN P30    [get_ports {FMC_HB_P[18]  }];
set_property PACKAGE_PIN P24    [get_ports {FMC_HB_N[19]  }];
set_property PACKAGE_PIN P23    [get_ports {FMC_HB_P[19]  }];
set_property PACKAGE_PIN P28    [get_ports {FMC_HB_N[20]  }];
set_property PACKAGE_PIN N28    [get_ports {FMC_HB_P[20]  }];
set_property PACKAGE_PIN P29    [get_ports {FMC_HB_N[21]  }];
set_property PACKAGE_PIN N29    [get_ports {FMC_HB_P[21]  }];


# -------------------------------------------------------------------
# On-board Clocks from APP PLL
# -------------------------------------------------------------------
# APP PLL OUT5 - Bank 9 (AD18/AD19) 100 Mhz  IO_L12P/N_T1_MRCC_9
# APP PLL OUT6 - Bank 9 (AA18/AA19) 100 Mhz  IO_L13P/N_T2_MRCC_9

set_property PACKAGE_PIN AD18 [get_ports {ZCLK_APPOUT0_P} ];
set_property PACKAGE_PIN AD19 [get_ports {ZCLK_APPOUT0_N} ];
set_property PACKAGE_PIN AA18 [get_ports {ZCLK_APPOUT1_P} ];
set_property PACKAGE_PIN AA19 [get_ports {ZCLK_APPOUT1_N} ];



# -------------------------------------------------------------------
# MGT REF CLKS
# -------------------------------------------------------------------
# - Bank 109 -
# - MGTREFCLK0 : FMC.GBTCLK0_M2C (Module to Carrier)
# - MGTREFCLK1 : DEVICE PLL OUT3 - ZCLK_DEVOUT3 (125 MHz)
# -------------------------------------------------------------------
# MGTREFCLK0 of bank 109, on FMC card
set_property PACKAGE_PIN AD10   [get_ports {FMC_CLK0_M2C_P}];
set_property PACKAGE_PIN AD9    [get_ports {FMC_CLK0_M2C_N}];

# MGTREFCLK1 of bank 109, 125 MHz
set_property PACKAGE_PIN AF10  [get_ports {GTXCLK0_P  }];
set_property PACKAGE_PIN AF9   [get_ports {GTXCLK0_N  }];


# -------------------------------------------------------------------
# - Bank 110 -
# - MGTREFCLK0 : FMC.GBTCLK1_M2C (Module to Carrier)
# - MGTREFCLK1 : DEVICE PLL OUT6 - ZCLK_DEVOUT6 (156.25 MHz)
# -------------------------------------------------------------------
# MGTREFCLK0 of bank 110, on FMC card
# (not available on Techway FMC_SFP/+_104)
set_property PACKAGE_PIN AA8    [get_ports {FMC_CLK1_M2C_P}];
set_property PACKAGE_PIN AA7    [get_ports {FMC_CLK1_M2C_N}];

# MGTREFCLK1 of bank 110, 156.25 MHz
set_property PACKAGE_PIN AC8   [get_ports {GTXCLK1_P  }];
set_property PACKAGE_PIN AC7   [get_ports {GTXCLK1_N  }];


# -------------------------------------------------------------------
# - Bank 111 -
# - MGTREFCLK0 : AMC.FCLKA (Module to Carrier)
# - MGTREFCLK1 : DEVICE PLL OUT4 - ZCLK_DEVOUT4 (125 MHz)
# -------------------------------------------------------------------
# MGTREFCLK0, AMC FCLKA pins (Module to Carrier)
set_property PACKAGE_PIN U8       [get_ports {AMC8_11_MGTREFCLK0_P  }];
set_property PACKAGE_PIN U7       [get_ports {AMC8_11_MGTREFCLK0_N  }];

# MGTREFCLK1, 125 MHz
set_property PACKAGE_PIN W8       [get_ports {AMC8_11_MGTREFCLK1_P  }];
set_property PACKAGE_PIN W7       [get_ports {AMC8_11_MGTREFCLK1_N  }];


# -------------------------------------------------------------------
# - Bank 112 -
# - MGTREFCLK0 : DEVICE PLL OUT1 - ZCLK_DEVOUT1 (100 MHz)
# - MGTREFCLK1 : DEVICE PLL OUT7 - ZCLK_DEVOUT7 (1256.25 MHz)
# -------------------------------------------------------------------
# MGTREFCLK0, 100 MHz
set_property PACKAGE_PIN N8       [get_ports {AMC4_7_MGTREFCLK0_P  }];
set_property PACKAGE_PIN N7       [get_ports {AMC4_7_MGTREFCLK0_N  }];

# MGTREFCLK1, 156.25 MHz
set_property PACKAGE_PIN R8       [get_ports {AMC4_7_MGTREFCLK1_P  }];
set_property PACKAGE_PIN R7       [get_ports {AMC4_7_MGTREFCLK1_N  }];



# -------------------------------------------------------------------
# SFP TX Enable (always)
# -------------------------------------------------------------------

# -------------------------------------------------------------------
# IOSTANDARD VCCOIO Constraints
# -------------------------------------------------------------------
# Set the bank voltage for IO Bank 34 to 1.8V by default.
#set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 34]];
# Set the bank voltage for IO Bank 35 to 1.8V by default.
#set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 35]];
# Set the bank voltage for IO Bank 13 to 3.3V by default.
#set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 13]];

# -------------------------------------------------------------------
# Override Differential Pairs' IOSTANDARD
# -------------------------------------------------------------------

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

# MGT_BANK_109
set FMC_HPC_GTX0_LOC  GTXE2_CHANNEL_X0Y0
set FMC_HPC_GTX1_LOC  GTXE2_CHANNEL_X0Y1
set FMC_HPC_GTX2_LOC  GTXE2_CHANNEL_X0Y2
set FMC_HPC_GTX3_LOC  GTXE2_CHANNEL_X0Y3

# MGT_BANK_112
set AMC_P4_GTX_LOC    GTXE2_CHANNEL_X0Y15
set AMC_P5_GTX_LOC    GTXE2_CHANNEL_X0Y14
set AMC_P6_GTX_LOC    GTXE2_CHANNEL_X0Y13
set AMC_P7_GTX_LOC    GTXE2_CHANNEL_X0Y12

# MGT_BANK_111
set AMC_P8_GTX_LOC    GTXE2_CHANNEL_X0Y11
set AMC_P9_GTX_LOC    GTXE2_CHANNEL_X0Y10
set AMC_P10_GTX_LOC   GTXE2_CHANNEL_X0Y9
set AMC_P11_GTX_LOC   GTXE2_CHANNEL_X0Y8
