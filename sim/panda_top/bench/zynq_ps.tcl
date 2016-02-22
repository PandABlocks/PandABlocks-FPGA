
################################################################
# This is a generated script based on design: zynq_ps
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2015.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   puts "ERROR: This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source zynq_ps_script.tcl

# If you do not already have a project created,
# you can create a project using the following command:
#    create_project project_1 myproj -part xc7z030sbg485-1

# CHECKING IF PROJECT EXISTS
if { [get_projects -quiet] eq "" } {
   puts "ERROR: Please open or create a project!"
   return 1
}



# CHANGE DESIGN NAME HERE
set design_name zynq_ps

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "ERROR: Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      puts "INFO: Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   puts "INFO: Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "ERROR: Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "ERROR: Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   puts "INFO: Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   puts "INFO: Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

puts "INFO: Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   puts $errMsg
   return $nRet
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     puts "ERROR: Unable to find parent cell <$parentCell>!"
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     puts "ERROR: Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set M00_AXI [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M00_AXI ]
  set_property -dict [ list CONFIG.ADDR_WIDTH {32} CONFIG.DATA_WIDTH {32} CONFIG.NUM_READ_OUTSTANDING {2} CONFIG.NUM_WRITE_OUTSTANDING {2} CONFIG.PROTOCOL {AXI4LITE}  ] $M00_AXI
  set S_AXI_HP0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_HP0 ]
  set_property -dict [ list CONFIG.ADDR_WIDTH {32} CONFIG.ARUSER_WIDTH {0} CONFIG.AWUSER_WIDTH {0} CONFIG.BUSER_WIDTH {0} CONFIG.CLK_DOMAIN {} CONFIG.DATA_WIDTH {32} CONFIG.FREQ_HZ {100000000} CONFIG.ID_WIDTH {6} CONFIG.MAX_BURST_LENGTH {16} CONFIG.NUM_READ_OUTSTANDING {2} CONFIG.NUM_WRITE_OUTSTANDING {2} CONFIG.PHASE {0.000} CONFIG.PROTOCOL {AXI4} CONFIG.READ_WRITE_MODE {WRITE_ONLY} CONFIG.RUSER_WIDTH {0} CONFIG.SUPPORTS_NARROW_BURST {1} CONFIG.WUSER_WIDTH {0}  ] $S_AXI_HP0

  # Create ports
  set FCLK_CLK0 [ create_bd_port -dir O -type clk FCLK_CLK0 ]
  set_property -dict [ list CONFIG.ASSOCIATED_BUSIF {M00_AXI:S_AXI_HP0}  ] $FCLK_CLK0
  set FCLK_RESET0_N [ create_bd_port -dir O -type rst FCLK_RESET0_N ]
  set IRQ_F2P [ create_bd_port -dir I -from 3 -to 0 -type intr IRQ_F2P ]
  set_property -dict [ list CONFIG.PortWidth {4}  ] $IRQ_F2P
  set PS_CLK [ create_bd_port -dir I PS_CLK ]
  set PS_PORB [ create_bd_port -dir I PS_PORB ]
  set PS_SRSTB [ create_bd_port -dir I PS_SRSTB ]

  # Create instance: axi, and set properties
  set axi [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi ]
  set_property -dict [ list CONFIG.NUM_MI {1}  ] $axi

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
  set_property -dict [ list CONFIG.NUM_MI {1}  ] $axi_interconnect_0

  # Create instance: hp1, and set properties
  set hp1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:cdn_axi_bfm:5.0 hp1 ]
  set_property -dict [ list CONFIG.C_PROTOCOL_SELECTION {0}  ] $hp1

  # Create instance: ps, and set properties
  set ps [ create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7_bfm:2.0 ps ]
  set_property -dict [ list CONFIG.PCW_FCLK_CLK0_FREQ {125000000} CONFIG.PCW_S_AXI_HP0_DATA_WIDTH {64} CONFIG.PCW_USE_M_AXI_GP0 {1} CONFIG.PCW_USE_S_AXI_HP0 {1} CONFIG.PCW_USE_S_AXI_HP1 {1}  ] $ps

  # Create interface connections
  connect_bd_intf_net -intf_net S_AXI_HP0_1 [get_bd_intf_ports S_AXI_HP0] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_ports M00_AXI] [get_bd_intf_pins axi/M00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI1 [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins ps/S_AXI_HP0]
  connect_bd_intf_net -intf_net cdn_axi_bfm_0_M_AXI3 [get_bd_intf_pins hp1/M_AXI3] [get_bd_intf_pins ps/S_AXI_HP1]
  connect_bd_intf_net -intf_net processing_system7_bfm_0_M_AXI_GP0 [get_bd_intf_pins axi/S00_AXI] [get_bd_intf_pins ps/M_AXI_GP0]

  # Create port connections
  connect_bd_net -net IRQ_F2P_1 [get_bd_ports IRQ_F2P] [get_bd_pins ps/IRQ_F2P]
  connect_bd_net -net PS_CLK_1 [get_bd_ports PS_CLK] [get_bd_pins ps/PS_CLK]
  connect_bd_net -net PS_PORB_1 [get_bd_ports PS_PORB] [get_bd_pins ps/PS_PORB]
  connect_bd_net -net PS_SRSTB_1 [get_bd_ports FCLK_RESET0_N] [get_bd_ports PS_SRSTB] [get_bd_pins axi/ARESETN] [get_bd_pins axi/M00_ARESETN] [get_bd_pins axi/S00_ARESETN] [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins hp1/m_axi_aresetn] [get_bd_pins ps/PS_SRSTB]
  connect_bd_net -net processing_system7_bfm_0_FCLK_CLK0 [get_bd_ports FCLK_CLK0] [get_bd_pins axi/ACLK] [get_bd_pins axi/M00_ACLK] [get_bd_pins axi/S00_ACLK] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins hp1/m_axi_aclk] [get_bd_pins ps/FCLK_CLK0] [get_bd_pins ps/M_AXI_GP0_ACLK] [get_bd_pins ps/S_AXI_HP0_ACLK] [get_bd_pins ps/S_AXI_HP1_ACLK]

  # Create address segments
  create_bd_addr_seg -range 0x40000000 -offset 0x0 [get_bd_addr_spaces hp1/Data] [get_bd_addr_segs ps/S_AXI_HP1/HP1_DDR_LOWOCM] SEG_processing_system7_bfm_0_HP1_DDR_LOWOCM
  create_bd_addr_seg -range 0x20000 -offset 0x43C00000 [get_bd_addr_spaces ps/Data] [get_bd_addr_segs M00_AXI/Reg] SEG_M00_AXI_Reg
  create_bd_addr_seg -range 0x40000000 -offset 0x0 [get_bd_addr_spaces S_AXI_HP0] [get_bd_addr_segs ps/S_AXI_HP0/HP0_DDR_LOWOCM] SEG_ps_HP0_DDR_LOWOCM
  

  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


puts "\n\nWARNING: This Tcl script was generated from a block design that has not been validated. It is possible that design <$design_name> may result in errors during validation."

