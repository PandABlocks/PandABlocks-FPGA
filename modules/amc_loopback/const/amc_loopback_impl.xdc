# -------------------------------------------------------------------
# Define asynchronous clocks
# -------------------------------------------------------------------
#set_clock_groups -asynchronous -group GTXCLK0_P
#set_clock_groups -asynchronous -group GTXCLK1_P
set_clock_groups -asynchronous -group [get_clocks \ 
{softblocks_inst/{{ block.name }}_inst/amcgtx_exdes_i1/amcgtx_support_i/amcgtx_init_i/U0/amcgtx_i/gt0_amcgtx_i/gtxe2_i/TXOUTCLK}]
set_clock_groups -asynchronous -group [get_clocks \ 
{softblocks_inst/{{ block.name }}_inst/amcgtx_exdes_i2/amcgtx_support_i/amcgtx_init_i/U0/amcgtx_i/gt0_amcgtx_i/gtxe2_i/TXOUTCLK}]
set_clock_groups -asynchronous -group [get_clocks \ 
{softblocks_inst/{{ block.name }}_inst/amcgtx_exdes_i3/amcgtx_support_i/amcgtx_init_i/U0/amcgtx_i/gt0_amcgtx_i/gtxe2_i/TXOUTCLK}]
set_clock_groups -asynchronous -group [get_clocks \ 
{softblocks_inst/{{ block.name }}_inst/amcgtx_exdes_i4/amcgtx_support_i/amcgtx_init_i/U0/amcgtx_i/gt0_amcgtx_i/gtxe2_i/TXOUTCLK}]

# -------------------------------------------------------------------
# AMC MGTs - Bank 112
# -------------------------------------------------------------------

set_property LOC $AMC_GTX0_LOC \
[get_cells softblocks_inst/{{ block.name }}_inst/amcgtx_exdes_i1/amcgtx_support_i/amcgtx_init_i/U0/amcgtx_i/gt0_amcgtx_i/gtxe2_i]
set_property LOC $AMC_GTX1_LOC \
[get_cells softblocks_inst/{{ block.name }}_inst/amcgtx_exdes_i2/amcgtx_support_i/amcgtx_init_i/U0/amcgtx_i/gt0_amcgtx_i/gtxe2_i]
set_property LOC $AMC_GTX2_LOC \
[get_cells softblocks_inst/{{ block.name }}_inst/amcgtx_exdes_i3/amcgtx_support_i/amcgtx_init_i/U0/amcgtx_i/gt0_amcgtx_i/gtxe2_i]
set_property LOC $AMC_GTX3_LOC \
[get_cells softblocks_inst/{{ block.name }}_inst/amcgtx_exdes_i4/amcgtx_support_i/amcgtx_init_i/U0/amcgtx_i/gt0_amcgtx_i/gtxe2_i]

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

