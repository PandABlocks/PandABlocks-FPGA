# -------------------------------------------------------------------
# FMC MGT pins - Bank 109
# -------------------------------------------------------------------

#set_property PACKAGE_PIN AH10   [get_ports {FMC_DP0_M2C_P}];
#set_property PACKAGE_PIN AH9    [get_ports {FMC_DP0_M2C_N}];
#set_property PACKAGE_PIN AK10   [get_ports {FMC_DP0_C2M_P}];
#set_property PACKAGE_PIN AK9    [get_ports {FMC_DP0_C2M_N}];
## info only implicite pin assignation by
## using "set_property LOC $FMC_HPC_GTX0_LOC ..." in your module's fmc_*_impl.xdc file

#set_property PACKAGE_PIN AJ8    [get_ports {FMC_DP1_M2C_P}];
#set_property PACKAGE_PIN AJ7    [get_ports {FMC_DP1_M2C_N}];
#set_property PACKAGE_PIN AK6    [get_ports {FMC_DP1_C2M_P}];
#set_property PACKAGE_PIN AK5    [get_ports {FMC_DP1_C2M_N}];
## info only implicite pin assignation by
## using "set_property LOC $FMC_HPC_GTX1_LOC ..." in your module's fmc_*_impl.xdc file

#set_property PACKAGE_PIN AG8    [get_ports {FMC_DP2_M2C_P}];
#set_property PACKAGE_PIN AG7    [get_ports {FMC_DP2_M2C_N}];
#set_property PACKAGE_PIN AJ4    [get_ports {FMC_DP2_C2M_P}];
#set_property PACKAGE_PIN AJ3    [get_ports {FMC_DP2_C2M_N}];
## info only implicite pin assignation by
## using "set_property LOC $FMC_HPC_GTX2_LOC ..." in your module's fmc_*_impl.xdc file

#set_property PACKAGE_PIN AE8    [get_ports {FMC_DP3_M2C_P}];
#set_property PACKAGE_PIN AE7    [get_ports {FMC_DP3_M2C_N}];
#set_property PACKAGE_PIN AK2    [get_ports {FMC_DP3_C2M_P}];
#set_property PACKAGE_PIN AK1    [get_ports {FMC_DP3_C2M_N}];
## info only implicite pin assignation by
## using "set_property LOC $FMC_HPC_GTX3_LOC ..." in your module's fmc_*_impl.xdc file

# if not all pin are used in your design and by using PACKAGE_PIN you could end up with the following error messages:
#ERROR: [Vivado 12-1411] Cannot set LOC property of ports, Site location is not valid [/home/thibaux/PandA/PandABlocks-FPGA_NAMC/targets/NAMC/const/FMC_MGT_pins.xdc:14]
#Resolution: Verify the location constraints for differential ports are correctly specified in your constraints. The Site type should be of form: IO_LxxP for P-side, and IO_LxxN for N-side (Neg Diff Pair) 
#ERROR: [Vivado 12-1411] Cannot set LOC property of ports, Site location is not valid [/home/thibaux/PandA/PandABlocks-FPGA_NAMC/targets/NAMC/const/FMC_MGT_pins.xdc:15]
#Resolution: Verify the location constraints for differential ports are correctly specified in your constraints. The Site type should be of form: IO_LxxP for P-side, and IO_LxxN for N-side (Neg Diff Pair) 
#ERROR: [Vivado 12-1411] Cannot set LOC property of ports, Site location is not valid [/home/thibaux/PandA/PandABlocks-FPGA_NAMC/targets/NAMC/const/FMC_MGT_pins.xdc:21]
#Resolution: Verify the location constraints for differential ports are correctly specified in your constraints. The Site type should be of form: IO_LxxP for P-side, and IO_LxxN for N-side (Neg Diff Pair) 
#ERROR: [Vivado 12-1411] Cannot set LOC property of ports, Site location is not valid [/home/thibaux/PandA/PandABlocks-FPGA_NAMC/targets/NAMC/const/FMC_MGT_pins.xdc:22]
#Resolution: Verify the location constraints for differential ports are correctly specified in your constraints. The Site type should be of form: IO_LxxP for P-side, and IO_LxxN for N-side (Neg Diff Pair) 
#ERROR: [Vivado 12-1411] Cannot set LOC property of ports, Site location is not valid [/home/thibaux/PandA/PandABlocks-FPGA_NAMC/targets/NAMC/const/FMC_MGT_pins.xdc:28]
#Resolution: Verify the location constraints for differential ports are correctly specified in your constraints. The Site type should be of form: IO_LxxP for P-side, and IO_LxxN for N-side (Neg Diff Pair) 
#ERROR: [Vivado 12-1411] Cannot set LOC property of ports, Site location is not valid [/home/thibaux/PandA/PandABlocks-FPGA_NAMC/targets/NAMC/const/FMC_MGT_pins.xdc:29]
#Resolution: Verify the location constraints for differential ports are correctly specified in your constraints. The Site type should be of form: IO_LxxP for P-side, and IO_LxxN for N-side (Neg Diff Pair) 
