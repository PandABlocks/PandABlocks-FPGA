#set_clock_groups -asynchronous -group [get_clocks \ 
#{softblocks_inst/{{ block.name }}_inst/fmc_adc_mezzanine/I}]


# -------------------------------------------------------------------
# FMC ADC clocks
# -------------------------------------------------------------------
# ADC_DCO_P/N   FMC_LA_P/N[0]     400 MHz
# ADC_FR_P/N    FMC_LA_P/N[1]     100 MHz

create_clock -period 2.500 -name ADC_DCO [get_ports {FMC_LA_P[0]}]

# ADC_DCO input is passed through a BUFIO ==> direct/dedicated routing to ISERDES.CLK inputs
# Timing cannot improve this and thus this path chould be excluded from timing checks.
# ADC_DCO input is passed through BUFR(divide) ==> normal clock routing to ISERDES.CLKDIV.
# This path must be under timing control because the clock is not only used for ISERDES.CLKDIV
# but also for normal clocked logic.

# Remove the path from ADC forwarded clock package pin to all ISERDES.CLK pins from timing
set_false_path -from [get_clocks ADC_DCO] -to [get_pins -hier -filter {name =~ *cmp_adc_iserdes/DDLY}]


# -------------------------------------------------------------------
# FMC IO STANDARD
# -------------------------------------------------------------------
set_property IOSTANDARD LVDS_25   [get_ports FMC_LA_N[0]   ];
set_property IOSTANDARD LVDS_25   [get_ports FMC_LA_P[0]   ];
set_property IOSTANDARD LVDS_25   [get_ports FMC_LA_N[1]   ];
set_property IOSTANDARD LVDS_25   [get_ports FMC_LA_P[1]   ];
set_property IOSTANDARD LVDS_25   [get_ports FMC_LA_N[14]  ];
set_property IOSTANDARD LVDS_25   [get_ports FMC_LA_P[14]  ];
set_property IOSTANDARD LVDS_25   [get_ports FMC_LA_N[15]  ];
set_property IOSTANDARD LVDS_25   [get_ports FMC_LA_P[15]  ];
set_property IOSTANDARD LVDS_25   [get_ports FMC_LA_N[16]  ];
set_property IOSTANDARD LVDS_25   [get_ports FMC_LA_P[16]  ];
set_property IOSTANDARD LVDS_25   [get_ports FMC_LA_N[13]  ];
set_property IOSTANDARD LVDS_25   [get_ports FMC_LA_P[13]  ];
set_property IOSTANDARD LVDS_25   [get_ports FMC_LA_N[10]  ];
set_property IOSTANDARD LVDS_25   [get_ports FMC_LA_P[10]  ];
set_property IOSTANDARD LVDS_25   [get_ports FMC_LA_N[9]   ];
set_property IOSTANDARD LVDS_25   [get_ports FMC_LA_P[9]   ];
set_property IOSTANDARD LVDS_25   [get_ports FMC_LA_N[7]   ];
set_property IOSTANDARD LVDS_25   [get_ports FMC_LA_P[7]   ];
set_property IOSTANDARD LVDS_25   [get_ports FMC_LA_N[5]   ];
set_property IOSTANDARD LVDS_25   [get_ports FMC_LA_P[5]   ];

set_property IOSTANDARD LVDS_25  [get_ports FMC_LA_N[17]  ];
set_property IOSTANDARD LVDS_25  [get_ports FMC_LA_P[17]  ];

set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_P[25]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_N[31]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_P[31]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_P[30]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_N[32]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_P[32]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_N[33]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_P[33]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_N[30]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_N[28]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_P[28]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_N[26]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_P[26]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_N[27]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_N[25]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_N[24]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_P[24]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_P[29]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_P[20]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_N[19]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_N[22]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_P[22]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_P[21]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_P[27]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_N[21]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_N[8]   ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_P[8]   ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_N[12]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_P[12]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_N[11]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_P[11]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_N[20]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_N[2]   ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_P[2]   ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_N[3]   ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_P[3]   ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_P[4]   ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_P[6]   ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_N[4]   ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_N[6]   ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_N[18]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_P[18]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_N[29]  ];
#set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_N[17]  ];
#set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_P[17]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_N[23]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_P[23]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_LA_P[19]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_HA_N[6]   ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_HA_P[6]   ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_HA_N[16]  ];
set_property IOSTANDARD LVCMOS25  [get_ports FMC_HA_P[16]  ];
