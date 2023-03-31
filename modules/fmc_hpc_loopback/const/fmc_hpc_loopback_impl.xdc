# -------------------------------------------------------------------
# Define asynchronous clocks
# -------------------------------------------------------------------
set_clock_groups -asynchronous -group [get_clocks \ 
{softblocks_inst/{{ block.name }}_inst/fmcgtx_exdes_i*/fmcgtx_support_i/fmcgtx_init_i/U0/fmcgtx_i/gt0_fmcgtx_i/gtxe2_i/TXOUTCLK}]

# -------------------------------------------------------------------
# FMC MGTs - Bank 109
# -------------------------------------------------------------------
set_property LOC $FMC_HPC_GTX0_LOC \
[get_cells softblocks_inst/{{ block.name }}_inst/fmcgtx_exdes_i0/fmcgtx_support_i/fmcgtx_init_i/U0/fmcgtx_i/gt0_fmcgtx_i/gtxe2_i]
set_property LOC $FMC_HPC_GTX1_LOC \
[get_cells softblocks_inst/{{ block.name }}_inst/fmcgtx_exdes_i1_3[1].fmcgtx_exdes/fmcgtx_support_i/fmcgtx_init_i/U0/fmcgtx_i/gt0_fmcgtx_i/gtxe2_i]
set_property LOC $FMC_HPC_GTX2_LOC \
[get_cells softblocks_inst/{{ block.name }}_inst/fmcgtx_exdes_i1_3[2].fmcgtx_exdes/fmcgtx_support_i/fmcgtx_init_i/U0/fmcgtx_i/gt0_fmcgtx_i/gtxe2_i]
set_property LOC $FMC_HPC_GTX3_LOC \
[get_cells softblocks_inst/{{ block.name }}_inst/fmcgtx_exdes_i1_3[3].fmcgtx_exdes/fmcgtx_support_i/fmcgtx_init_i/U0/fmcgtx_i/gt0_fmcgtx_i/gtxe2_i]

# -------------------------------------------------------------------
# Async false reset paths
# -------------------------------------------------------------------
# If running into timing problems, try uncommenting the lines below ...
#set_false_path -to [get_pins -hierarchical -filter {NAME =~ *_txfsmresetdone_r*/CLR}]
#set_false_path -to [get_pins -hierarchical -filter {NAME =~ *_txfsmresetdone_r*/D}]
#set_false_path -to [get_pins -hierarchical -filter {NAME =~ *reset_on_error_in_r*/D}]

# FMC [33:17] are inputs
#set_false_path -from [lrange [get_ports -regexp FMC_LA_P.*] 1 16]
#set_false_path -from [lrange [get_ports -regexp FMC_LA_N.*] 1 16]

# -------------------------------------------------------------------
# FMC IO STANDARD
# -------------------------------------------------------------------
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_N[*]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_LA_P[*]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_N[*]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HA_P[*]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_N[*]   ];
set_property IOSTANDARD LVCMOS18   [get_ports FMC_HB_P[*]   ];
