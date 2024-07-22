# -------------------------------------------------------------------
# Enable on-chip pulldown for floating FMC_IN[0-7] inputs
# -------------------------------------------------------------------
set_property PULLTYPE PULLDOWN [get_ports FMC_LA_P[*]]
set_property PULLTYPE PULLDOWN [get_ports FMC_LA_N[*]]

