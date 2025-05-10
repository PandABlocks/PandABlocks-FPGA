set_property BITSTREAM.CONFIG.UNUSEDPIN PULLNONE [current_design]

# MGT Reference Clocks
set_property PACKAGE_PIN C7 [get_ports GTXCLK0_N]
set_property PACKAGE_PIN C8 [get_ports GTXCLK0_P]

set_property PACKAGE_PIN G7       [get_ports {FMC_HPC0_GBTCLK0_M2C_C_N}] ;# Bank 229 - MGTREFCLK0N_229
set_property PACKAGE_PIN G8       [get_ports {FMC_HPC0_GBTCLK0_M2C_C_P}] ;# Bank 229 - MGTREFCLK0P_229
set_property PACKAGE_PIN L7       [get_ports {FMC_HPC0_GBTCLK1_M2C_C_N}] ;# Bank 228 - MGTREFCLK0N_228
set_property PACKAGE_PIN L8       [get_ports {FMC_HPC0_GBTCLK1_M2C_C_P}] ;# Bank 228 - MGTREFCLK0P_228

set_property PACKAGE_PIN R8       [get_ports {FMC_CLK0_M2C_N[0]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L12N_T1U_N11_GC_67
set_property IOSTANDARD  LVDS     [get_ports {FMC_CLK0_M2C_N[0]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L12N_T1U_N11_GC_67
set_property PACKAGE_PIN T8       [get_ports {FMC_CLK0_M2C_P[0]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L12P_T1U_N10_GC_67
set_property IOSTANDARD  LVDS     [get_ports {FMC_CLK0_M2C_P[0]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L12P_T1U_N10_GC_67

set_property PACKAGE_PIN AA6      [get_ports {FMC_CLK1_M2C_N[0]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L12N_T1U_N11_GC_66
set_property IOSTANDARD  LVDS     [get_ports {FMC_CLK1_M2C_N[0]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L12N_T1U_N11_GC_66
set_property PACKAGE_PIN AA7      [get_ports {FMC_CLK1_M2C_P[0]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L12P_T1U_N10_GC_66
set_property IOSTANDARD  LVDS     [get_ports {FMC_CLK1_M2C_P[0]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L12P_T1U_N10_GC_66

set_property PACKAGE_PIN Y3       [get_ports {FMC_LA_N[0][0]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L13N_T2L_N1_GC_QBC_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][0]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L13N_T2L_N1_GC_QBC_66
set_property PACKAGE_PIN Y4       [get_ports {FMC_LA_P[0][0]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L13P_T2L_N0_GC_QBC_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][0]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L13P_T2L_N0_GC_QBC_66
set_property PACKAGE_PIN AC4      [get_ports {FMC_LA_N[0][1]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L16N_T2U_N7_QBC_AD3N_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][1]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L16N_T2U_N7_QBC_AD3N_66
set_property PACKAGE_PIN AB4      [get_ports {FMC_LA_P[0][1]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L16P_T2U_N6_QBC_AD3P_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][1]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L16P_T2U_N6_QBC_AD3P_66
set_property PACKAGE_PIN V1       [get_ports {FMC_LA_N[0][2]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L23N_T3U_N9_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][2]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L23N_T3U_N9_66
set_property PACKAGE_PIN V2       [get_ports {FMC_LA_P[0][2]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L23P_T3U_N8_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][2]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L23P_T3U_N8_66
set_property PACKAGE_PIN Y1       [get_ports {FMC_LA_N[0][3]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L22N_T3U_N7_DBC_AD0N_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][3]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L22N_T3U_N7_DBC_AD0N_66
set_property PACKAGE_PIN Y2       [get_ports {FMC_LA_P[0][3]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L22P_T3U_N6_DBC_AD0P_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][3]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L22P_T3U_N6_DBC_AD0P_66
set_property PACKAGE_PIN AA1      [get_ports {FMC_LA_N[0][4]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L21N_T3L_N5_AD8N_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][4]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L21N_T3L_N5_AD8N_66
set_property PACKAGE_PIN AA2      [get_ports {FMC_LA_P[0][4]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L21P_T3L_N4_AD8P_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][4]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L21P_T3L_N4_AD8P_66
set_property PACKAGE_PIN AC3      [get_ports {FMC_LA_N[0][5]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L20N_T3L_N3_AD1N_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][5]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L20N_T3L_N3_AD1N_66
set_property PACKAGE_PIN AB3      [get_ports {FMC_LA_P[0][5]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L20P_T3L_N2_AD1P_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][5]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L20P_T3L_N2_AD1P_66
set_property PACKAGE_PIN AC1      [get_ports {FMC_LA_N[0][6]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L19N_T3L_N1_DBC_AD9N_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][6]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L19N_T3L_N1_DBC_AD9N_66
set_property PACKAGE_PIN AC2      [get_ports {FMC_LA_P[0][6]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L19P_T3L_N0_DBC_AD9P_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][6]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L19P_T3L_N0_DBC_AD9P_66
set_property PACKAGE_PIN U4       [get_ports {FMC_LA_N[0][7]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L18N_T2U_N11_AD2N_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][7]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L18N_T2U_N11_AD2N_66
set_property PACKAGE_PIN U5       [get_ports {FMC_LA_P[0][7]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L18P_T2U_N10_AD2P_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][7]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L18P_T2U_N10_AD2P_66
set_property PACKAGE_PIN V3       [get_ports {FMC_LA_N[0][8]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L17N_T2U_N9_AD10N_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][8]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L17N_T2U_N9_AD10N_66
set_property PACKAGE_PIN V4       [get_ports {FMC_LA_P[0][8]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L17P_T2U_N8_AD10P_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][8]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L17P_T2U_N8_AD10P_66
set_property PACKAGE_PIN W1       [get_ports {FMC_LA_N[0][9]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L24N_T3U_N11_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][9]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L24N_T3U_N11_66
set_property PACKAGE_PIN W2       [get_ports {FMC_LA_P[0][9]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L24P_T3U_N10_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][9]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L24P_T3U_N10_66
set_property PACKAGE_PIN W4       [get_ports {FMC_LA_N[0][10]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L15N_T2L_N5_AD11N_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][10]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L15N_T2L_N5_AD11N_66
set_property PACKAGE_PIN W5       [get_ports {FMC_LA_P[0][10]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L15P_T2L_N4_AD11P_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][10]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L15P_T2L_N4_AD11P_66
set_property PACKAGE_PIN AB5      [get_ports {FMC_LA_N[0][11]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L10N_T1U_N7_QBC_AD4N_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][11]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L10N_T1U_N7_QBC_AD4N_66
set_property PACKAGE_PIN AB6      [get_ports {FMC_LA_P[0][11]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L10P_T1U_N6_QBC_AD4P_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][11]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L10P_T1U_N6_QBC_AD4P_66
set_property PACKAGE_PIN W6       [get_ports {FMC_LA_N[0][12]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L9N_T1L_N5_AD12N_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][12]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L9N_T1L_N5_AD12N_66
set_property PACKAGE_PIN W7       [get_ports {FMC_LA_P[0][12]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L9P_T1L_N4_AD12P_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][12]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L9P_T1L_N4_AD12P_66
set_property PACKAGE_PIN AC8      [get_ports {FMC_LA_N[0][13]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L8N_T1L_N3_AD5N_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][13]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L8N_T1L_N3_AD5N_66
set_property PACKAGE_PIN AB8      [get_ports {FMC_LA_P[0][13]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L8P_T1L_N2_AD5P_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][13]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L8P_T1L_N2_AD5P_66
set_property PACKAGE_PIN AC6      [get_ports {FMC_LA_N[0][14]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L7N_T1L_N1_QBC_AD13N_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][14]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L7N_T1L_N1_QBC_AD13N_66
set_property PACKAGE_PIN AC7      [get_ports {FMC_LA_P[0][14]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L7P_T1L_N0_QBC_AD13P_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][14]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L7P_T1L_N0_QBC_AD13P_66
set_property PACKAGE_PIN Y9       [get_ports {FMC_LA_N[0][15]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L6N_T0U_N11_AD6N_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][15]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L6N_T0U_N11_AD6N_66
set_property PACKAGE_PIN Y10      [get_ports {FMC_LA_P[0][15]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L6P_T0U_N10_AD6P_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][15]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L6P_T0U_N10_AD6P_66
set_property PACKAGE_PIN AA12     [get_ports {FMC_LA_N[0][16]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L5N_T0U_N9_AD14N_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][16]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L5N_T0U_N9_AD14N_66
set_property PACKAGE_PIN Y12      [get_ports {FMC_LA_P[0][16]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L5P_T0U_N8_AD14P_66
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][16]}] ;# Bank  66 VCCO - VADJ_FMC - IO_L5P_T0U_N8_AD14P_66
set_property PACKAGE_PIN N11      [get_ports {FMC_LA_N[0][17]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L13N_T2L_N1_GC_QBC_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][17]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L13N_T2L_N1_GC_QBC_67
set_property PACKAGE_PIN P11      [get_ports {FMC_LA_P[0][17]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L13P_T2L_N0_GC_QBC_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][17]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L13P_T2L_N0_GC_QBC_67
set_property PACKAGE_PIN N8       [get_ports {FMC_LA_N[0][18]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L16N_T2U_N7_QBC_AD3N_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][18]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L16N_T2U_N7_QBC_AD3N_67
set_property PACKAGE_PIN N9       [get_ports {FMC_LA_P[0][18]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L16P_T2U_N6_QBC_AD3P_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][18]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L16P_T2U_N6_QBC_AD3P_67
set_property PACKAGE_PIN K13      [get_ports {FMC_LA_N[0][19]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L23N_T3U_N9_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][19]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L23N_T3U_N9_67
set_property PACKAGE_PIN L13      [get_ports {FMC_LA_P[0][19]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L23P_T3U_N8_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][19]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L23P_T3U_N8_67
set_property PACKAGE_PIN M13      [get_ports {FMC_LA_N[0][20]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L22N_T3U_N7_DBC_AD0N_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][20]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L22N_T3U_N7_DBC_AD0N_67
set_property PACKAGE_PIN N13      [get_ports {FMC_LA_P[0][20]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L22P_T3U_N6_DBC_AD0P_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][20]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L22P_T3U_N6_DBC_AD0P_67
set_property PACKAGE_PIN N12      [get_ports {FMC_LA_N[0][21]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L21N_T3L_N5_AD8N_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][21]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L21N_T3L_N5_AD8N_67
set_property PACKAGE_PIN P12      [get_ports {FMC_LA_P[0][21]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L21P_T3L_N4_AD8P_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][21]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L21P_T3L_N4_AD8P_67
set_property PACKAGE_PIN M14      [get_ports {FMC_LA_N[0][22]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L20N_T3L_N3_AD1N_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][22]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L20N_T3L_N3_AD1N_67
set_property PACKAGE_PIN M15      [get_ports {FMC_LA_P[0][22]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L20P_T3L_N2_AD1P_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][22]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L20P_T3L_N2_AD1P_67
set_property PACKAGE_PIN K16      [get_ports {FMC_LA_N[0][23]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L19N_T3L_N1_DBC_AD9N_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][23]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L19N_T3L_N1_DBC_AD9N_67
set_property PACKAGE_PIN L16      [get_ports {FMC_LA_P[0][23]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L19P_T3L_N0_DBC_AD9P_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][23]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L19P_T3L_N0_DBC_AD9P_67
set_property PACKAGE_PIN K12      [get_ports {FMC_LA_N[0][24]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L18N_T2U_N11_AD2N_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][24]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L18N_T2U_N11_AD2N_67
set_property PACKAGE_PIN L12      [get_ports {FMC_LA_P[0][24]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L18P_T2U_N10_AD2P_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][24]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L18P_T2U_N10_AD2P_67
set_property PACKAGE_PIN L11      [get_ports {FMC_LA_N[0][25]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L17N_T2U_N9_AD10N_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][25]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L17N_T2U_N9_AD10N_67
set_property PACKAGE_PIN M11      [get_ports {FMC_LA_P[0][25]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L17P_T2U_N8_AD10P_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][25]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L17P_T2U_N8_AD10P_67
set_property PACKAGE_PIN K15      [get_ports {FMC_LA_N[0][26]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L24N_T3U_N11_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][26]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L24N_T3U_N11_67
set_property PACKAGE_PIN L15      [get_ports {FMC_LA_P[0][26]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L24P_T3U_N10_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][26]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L24P_T3U_N10_67
set_property PACKAGE_PIN L10      [get_ports {FMC_LA_N[0][27]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L15N_T2L_N5_AD11N_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][27]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L15N_T2L_N5_AD11N_67
set_property PACKAGE_PIN M10      [get_ports {FMC_LA_P[0][27]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L15P_T2L_N4_AD11P_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][27]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L15P_T2L_N4_AD11P_67
set_property PACKAGE_PIN T6       [get_ports {FMC_LA_N[0][28]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L10N_T1U_N7_QBC_AD4N_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][28]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L10N_T1U_N7_QBC_AD4N_67
set_property PACKAGE_PIN T7       [get_ports {FMC_LA_P[0][28]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L10P_T1U_N6_QBC_AD4P_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][28]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L10P_T1U_N6_QBC_AD4P_67
set_property PACKAGE_PIN U8       [get_ports {FMC_LA_N[0][29]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L9N_T1L_N5_AD12N_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][29]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L9N_T1L_N5_AD12N_67
set_property PACKAGE_PIN U9       [get_ports {FMC_LA_P[0][29]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L9P_T1L_N4_AD12P_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][29]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L9P_T1L_N4_AD12P_67
set_property PACKAGE_PIN U6       [get_ports {FMC_LA_N[0][30]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L8N_T1L_N3_AD5N_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][30]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L8N_T1L_N3_AD5N_67
set_property PACKAGE_PIN V6       [get_ports {FMC_LA_P[0][30]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L8P_T1L_N2_AD5P_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][30]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L8P_T1L_N2_AD5P_67
set_property PACKAGE_PIN V7       [get_ports {FMC_LA_N[0][31]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L7N_T1L_N1_QBC_AD13N_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][31]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L7N_T1L_N1_QBC_AD13N_67
set_property PACKAGE_PIN V8       [get_ports {FMC_LA_P[0][31]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L7P_T1L_N0_QBC_AD13P_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][31]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L7P_T1L_N0_QBC_AD13P_67
set_property PACKAGE_PIN T11      [get_ports {FMC_LA_N[0][32]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L6N_T0U_N11_AD6N_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][32]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L6N_T0U_N11_AD6N_67
set_property PACKAGE_PIN U11      [get_ports {FMC_LA_P[0][32]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L6P_T0U_N10_AD6P_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][32]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L6P_T0U_N10_AD6P_67
set_property PACKAGE_PIN V11      [get_ports {FMC_LA_N[0][33]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L5N_T0U_N9_AD14N_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_N[0][33]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L5N_T0U_N9_AD14N_67
set_property PACKAGE_PIN V12      [get_ports {FMC_LA_P[0][33]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L5P_T0U_N8_AD14P_67
set_property IOSTANDARD  LVCMOS18 [get_ports {FMC_LA_P[0][33]}] ;# Bank  67 VCCO - VADJ_FMC - IO_L5P_T0U_N8_AD14P_67

#set_property PACKAGE_PIN J10      [get_ports {PL_I2C0_SCL_LS}] ;# Bank  50 VCCO - VCC3V3   - IO_L1N_AD15N_50
#set_property IOSTANDARD  LVCMOS33 [get_ports {PL_I2C0_SCL_LS}] ;# Bank  50 VCCO - VCC3V3   - IO_L1N_AD15N_50
#set_property PACKAGE_PIN J11      [get_ports {PL_I2C0_SDA_LS}] ;# Bank  50 VCCO - VCC3V3   - IO_L1P_AD15P_50
#set_property IOSTANDARD  LVCMOS33 [get_ports {PL_I2C0_SDA_LS}] ;# Bank  50 VCCO - VCC3V3   - IO_L1P_AD15P_50

set_property PACKAGE_PIN J10      [get_ports {I2C_SCL_FPGA}] ;# Bank  50 VCCO - VCC3V3   - IO_L1N_AD15N_50
set_property IOSTANDARD  LVCMOS33 [get_ports {I2C_SCL_FPGA}] ;# Bank  50 VCCO - VCC3V3   - IO_L1N_AD15N_50
set_property PACKAGE_PIN J11      [get_ports {I2C_SDA_FPGA}] ;# Bank  50 VCCO - VCC3V3   - IO_L1P_AD15P_50
set_property IOSTANDARD  LVCMOS33 [get_ports {I2C_SDA_FPGA}] ;# Bank  50 VCCO - VCC3V3   - IO_L1P_AD15P_50

#set_property PACKAGE_PIN K20      [get_ports {PL_I2C1_SCL_LS}] ;# Bank  47 VCCO - VCC3V3   - IO_L1N_AD11N_47
#set_property IOSTANDARD  LVCMOS33 [get_ports {PL_I2C1_SCL_LS}] ;# Bank  47 VCCO - VCC3V3   - IO_L1N_AD11N_47
#set_property PACKAGE_PIN L20      [get_ports {PL_I2C1_SDA_LS}] ;# Bank  47 VCCO - VCC3V3   - IO_L1P_AD11P_47
#set_property IOSTANDARD  LVCMOS33 [get_ports {PL_I2C1_SDA_LS}] ;# Bank  47 VCCO - VCC3V3   - IO_L1P_AD11P_47


set SFP1_LOC GTHE4_CHANNEL_X1Y12
set SFP2_LOC GTHE4_CHANNEL_X1Y13
set SFP3_LOC GTHE4_CHANNEL_X1Y14
set SFP4_LOC GTHE4_CHANNEL_X1Y15
set FMC_MGT1_LOC GTHE4_CHANNEL_X1Y10
set FMC_MGT2_LOC GTHE4_CHANNEL_X1Y9
set FMC_MGT3_LOC GTHE4_CHANNEL_X1Y11
set FMC_MGT4_LOC GTHE4_CHANNEL_X1Y8

