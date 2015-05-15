
################################################################
# This is a generated script based on design: panda_ps
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
# source panda_ps_script.tcl

# If you do not already have a project created,
# you can create a project using the following command:
#    create_project project_1 myproj -part xc7z030sbg485-1
#    set_property BOARD_PART em.avnet.com:picozed_7030:part0:1.0 [current_project]

# CHECKING IF PROJECT EXISTS
if { [get_projects -quiet] eq "" } {
   puts "ERROR: Please open or create a project!"
   return 1
}



# CHANGE DESIGN NAME HERE
set design_name panda_ps

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
  set DDR [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 DDR ]
  set FIXED_IO [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_processing_system7:fixedio_rtl:1.0 FIXED_IO ]
  set M00_AXI [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 M00_AXI ]
  set_property -dict [ list CONFIG.ADDR_WIDTH {32} CONFIG.DATA_WIDTH {32} CONFIG.PROTOCOL {AXI4LITE}  ] $M00_AXI

  # Create ports
  set FCLK_CLK0 [ create_bd_port -dir O -type clk FCLK_CLK0 ]
  set_property -dict [ list CONFIG.ASSOCIATED_BUSIF {M00_AXI}  ] $FCLK_CLK0
  set FCLK_LEDS [ create_bd_port -dir O -from 31 -to 0 FCLK_LEDS ]
  set FCLK_RESET0_N [ create_bd_port -dir O -from 0 -to 0 -type rst FCLK_RESET0_N ]

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
  set_property -dict [ list CONFIG.NUM_MI {2}  ] $axi_interconnect_0

  # Create instance: c_counter_binary_0, and set properties
  set c_counter_binary_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:c_counter_binary:12.0 c_counter_binary_0 ]
  set_property -dict [ list CONFIG.Output_Width {32}  ] $c_counter_binary_0

  # Create instance: ila_0, and set properties
  set ila_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:5.1 ila_0 ]
  set_property -dict [ list CONFIG.C_MONITOR_TYPE {Native} CONFIG.C_PROBE0_WIDTH {32}  ] $ila_0

  # Create instance: panda_pcap_0, and set properties
  set panda_pcap_0 [ create_bd_cell -type ip -vlnv dls_cs1:user:panda_pcap:1.0 panda_pcap_0 ]

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]

  # Create instance: processing_system7_0, and set properties
  set processing_system7_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0 ]
  set_property -dict [ list CONFIG.PCW_APU_CLK_RATIO_ENABLE {6:2:1} \
CONFIG.PCW_APU_PERIPHERAL_FREQMHZ {666.666666} CONFIG.PCW_CPU_PERIPHERAL_CLKSRC {ARM PLL} \
CONFIG.PCW_CRYSTAL_PERIPHERAL_FREQMHZ {33.333333} CONFIG.PCW_DDR_PERIPHERAL_CLKSRC {DDR PLL} \
CONFIG.PCW_ENET0_ENET0_IO {MIO 16 .. 27} CONFIG.PCW_ENET0_GRP_MDIO_ENABLE {1} \
CONFIG.PCW_ENET0_GRP_MDIO_IO {MIO 52 .. 53} CONFIG.PCW_ENET0_PERIPHERAL_CLKSRC {IO PLL} \
CONFIG.PCW_ENET0_PERIPHERAL_ENABLE {1} CONFIG.PCW_ENET0_PERIPHERAL_FREQMHZ {1000 Mbps} \
CONFIG.PCW_ENET0_RESET_ENABLE {1} CONFIG.PCW_ENET0_RESET_IO {MIO 47} \
CONFIG.PCW_EN_CLK0_PORT {1} CONFIG.PCW_EN_CLK1_PORT {0} \
CONFIG.PCW_EN_CLK2_PORT {0} CONFIG.PCW_EN_CLK3_PORT {0} \
CONFIG.PCW_EN_DDR {1} CONFIG.PCW_EN_RST0_PORT {1} \
CONFIG.PCW_EN_RST1_PORT {0} CONFIG.PCW_EN_RST2_PORT {0} \
CONFIG.PCW_EN_RST3_PORT {0} CONFIG.PCW_FCLK0_PERIPHERAL_CLKSRC {IO PLL} \
CONFIG.PCW_FCLK1_PERIPHERAL_CLKSRC {IO PLL} CONFIG.PCW_FCLK2_PERIPHERAL_CLKSRC {IO PLL} \
CONFIG.PCW_FCLK3_PERIPHERAL_CLKSRC {IO PLL} CONFIG.PCW_FCLK_CLK0_BUF {true} \
CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} CONFIG.PCW_FPGA1_PERIPHERAL_FREQMHZ {100} \
CONFIG.PCW_FPGA2_PERIPHERAL_FREQMHZ {33.333333} CONFIG.PCW_FPGA3_PERIPHERAL_FREQMHZ {50} \
CONFIG.PCW_GPIO_EMIO_GPIO_ENABLE {0} CONFIG.PCW_GPIO_MIO_GPIO_ENABLE {1} \
CONFIG.PCW_GPIO_PERIPHERAL_ENABLE {1} CONFIG.PCW_IRQ_F2P_INTR {1} \
CONFIG.PCW_MIO_0_PULLUP {disabled} CONFIG.PCW_MIO_0_SLEW {slow} \
CONFIG.PCW_MIO_10_PULLUP {disabled} CONFIG.PCW_MIO_10_SLEW {slow} \
CONFIG.PCW_MIO_11_PULLUP {disabled} CONFIG.PCW_MIO_11_SLEW {slow} \
CONFIG.PCW_MIO_12_PULLUP {disabled} CONFIG.PCW_MIO_12_SLEW {slow} \
CONFIG.PCW_MIO_13_PULLUP {disabled} CONFIG.PCW_MIO_13_SLEW {slow} \
CONFIG.PCW_MIO_14_PULLUP {disabled} CONFIG.PCW_MIO_14_SLEW {slow} \
CONFIG.PCW_MIO_15_PULLUP {disabled} CONFIG.PCW_MIO_15_SLEW {slow} \
CONFIG.PCW_MIO_16_PULLUP {disabled} CONFIG.PCW_MIO_16_SLEW {slow} \
CONFIG.PCW_MIO_17_PULLUP {disabled} CONFIG.PCW_MIO_17_SLEW {slow} \
CONFIG.PCW_MIO_18_PULLUP {disabled} CONFIG.PCW_MIO_18_SLEW {slow} \
CONFIG.PCW_MIO_19_PULLUP {disabled} CONFIG.PCW_MIO_19_SLEW {slow} \
CONFIG.PCW_MIO_1_PULLUP {disabled} CONFIG.PCW_MIO_1_SLEW {slow} \
CONFIG.PCW_MIO_20_PULLUP {disabled} CONFIG.PCW_MIO_20_SLEW {slow} \
CONFIG.PCW_MIO_21_PULLUP {disabled} CONFIG.PCW_MIO_21_SLEW {slow} \
CONFIG.PCW_MIO_22_PULLUP {disabled} CONFIG.PCW_MIO_22_SLEW {slow} \
CONFIG.PCW_MIO_23_PULLUP {disabled} CONFIG.PCW_MIO_23_SLEW {slow} \
CONFIG.PCW_MIO_24_PULLUP {disabled} CONFIG.PCW_MIO_24_SLEW {slow} \
CONFIG.PCW_MIO_25_PULLUP {disabled} CONFIG.PCW_MIO_25_SLEW {slow} \
CONFIG.PCW_MIO_26_PULLUP {disabled} CONFIG.PCW_MIO_26_SLEW {slow} \
CONFIG.PCW_MIO_27_PULLUP {disabled} CONFIG.PCW_MIO_27_SLEW {slow} \
CONFIG.PCW_MIO_28_PULLUP {disabled} CONFIG.PCW_MIO_28_SLEW {slow} \
CONFIG.PCW_MIO_29_PULLUP {disabled} CONFIG.PCW_MIO_29_SLEW {slow} \
CONFIG.PCW_MIO_2_SLEW {slow} CONFIG.PCW_MIO_30_PULLUP {disabled} \
CONFIG.PCW_MIO_30_SLEW {slow} CONFIG.PCW_MIO_31_PULLUP {disabled} \
CONFIG.PCW_MIO_31_SLEW {slow} CONFIG.PCW_MIO_32_PULLUP {disabled} \
CONFIG.PCW_MIO_32_SLEW {slow} CONFIG.PCW_MIO_33_PULLUP {disabled} \
CONFIG.PCW_MIO_33_SLEW {slow} CONFIG.PCW_MIO_34_PULLUP {disabled} \
CONFIG.PCW_MIO_34_SLEW {slow} CONFIG.PCW_MIO_35_PULLUP {disabled} \
CONFIG.PCW_MIO_35_SLEW {slow} CONFIG.PCW_MIO_36_PULLUP {disabled} \
CONFIG.PCW_MIO_36_SLEW {slow} CONFIG.PCW_MIO_37_PULLUP {disabled} \
CONFIG.PCW_MIO_37_SLEW {slow} CONFIG.PCW_MIO_38_PULLUP {disabled} \
CONFIG.PCW_MIO_38_SLEW {slow} CONFIG.PCW_MIO_39_PULLUP {disabled} \
CONFIG.PCW_MIO_39_SLEW {slow} CONFIG.PCW_MIO_3_SLEW {slow} \
CONFIG.PCW_MIO_40_PULLUP {disabled} CONFIG.PCW_MIO_40_SLEW {slow} \
CONFIG.PCW_MIO_41_PULLUP {disabled} CONFIG.PCW_MIO_41_SLEW {slow} \
CONFIG.PCW_MIO_42_PULLUP {disabled} CONFIG.PCW_MIO_42_SLEW {slow} \
CONFIG.PCW_MIO_43_PULLUP {disabled} CONFIG.PCW_MIO_43_SLEW {slow} \
CONFIG.PCW_MIO_44_PULLUP {disabled} CONFIG.PCW_MIO_44_SLEW {slow} \
CONFIG.PCW_MIO_45_PULLUP {disabled} CONFIG.PCW_MIO_45_SLEW {slow} \
CONFIG.PCW_MIO_46_PULLUP {disabled} CONFIG.PCW_MIO_46_SLEW {slow} \
CONFIG.PCW_MIO_47_PULLUP {disabled} CONFIG.PCW_MIO_47_SLEW {slow} \
CONFIG.PCW_MIO_48_PULLUP {disabled} CONFIG.PCW_MIO_48_SLEW {slow} \
CONFIG.PCW_MIO_49_PULLUP {disabled} CONFIG.PCW_MIO_49_SLEW {slow} \
CONFIG.PCW_MIO_4_SLEW {slow} CONFIG.PCW_MIO_50_PULLUP {disabled} \
CONFIG.PCW_MIO_50_SLEW {slow} CONFIG.PCW_MIO_51_PULLUP {disabled} \
CONFIG.PCW_MIO_51_SLEW {slow} CONFIG.PCW_MIO_52_PULLUP {disabled} \
CONFIG.PCW_MIO_52_SLEW {slow} CONFIG.PCW_MIO_53_PULLUP {disabled} \
CONFIG.PCW_MIO_53_SLEW {slow} CONFIG.PCW_MIO_5_SLEW {slow} \
CONFIG.PCW_MIO_6_SLEW {slow} CONFIG.PCW_MIO_7_SLEW {slow} \
CONFIG.PCW_MIO_8_SLEW {slow} CONFIG.PCW_MIO_9_PULLUP {disabled} \
CONFIG.PCW_MIO_9_SLEW {slow} CONFIG.PCW_PACKAGE_NAME {sbg485} \
CONFIG.PCW_PRESET_BANK0_VOLTAGE {LVCMOS 3.3V} CONFIG.PCW_PRESET_BANK1_VOLTAGE {LVCMOS 1.8V} \
CONFIG.PCW_QSPI_GRP_FBCLK_ENABLE {1} CONFIG.PCW_QSPI_GRP_FBCLK_IO {MIO 8} \
CONFIG.PCW_QSPI_GRP_SINGLE_SS_ENABLE {1} CONFIG.PCW_QSPI_GRP_SINGLE_SS_IO {MIO 1 .. 6} \
CONFIG.PCW_QSPI_PERIPHERAL_CLKSRC {IO PLL} CONFIG.PCW_QSPI_PERIPHERAL_ENABLE {1} \
CONFIG.PCW_QSPI_PERIPHERAL_FREQMHZ {200} CONFIG.PCW_SD0_GRP_CD_ENABLE {1} \
CONFIG.PCW_SD0_GRP_CD_IO {MIO 46} CONFIG.PCW_SD0_GRP_WP_ENABLE {0} \
CONFIG.PCW_SD0_PERIPHERAL_ENABLE {1} CONFIG.PCW_SD0_SD0_IO {MIO 40 .. 45} \
CONFIG.PCW_SD1_PERIPHERAL_ENABLE {0} CONFIG.PCW_SDIO_PERIPHERAL_CLKSRC {IO PLL} \
CONFIG.PCW_SDIO_PERIPHERAL_FREQMHZ {50} CONFIG.PCW_TTC0_CLK0_PERIPHERAL_CLKSRC {CPU_1X} \
CONFIG.PCW_TTC0_CLK1_PERIPHERAL_CLKSRC {CPU_1X} CONFIG.PCW_TTC0_CLK2_PERIPHERAL_CLKSRC {CPU_1X} \
CONFIG.PCW_TTC0_PERIPHERAL_ENABLE {1} CONFIG.PCW_TTC0_TTC0_IO {EMIO} \
CONFIG.PCW_UART1_PERIPHERAL_ENABLE {1} CONFIG.PCW_UART1_UART1_IO {MIO 48 .. 49} \
CONFIG.PCW_UART_PERIPHERAL_CLKSRC {IO PLL} CONFIG.PCW_UART_PERIPHERAL_FREQMHZ {50} \
CONFIG.PCW_UIPARAM_ACT_DDR_FREQ_MHZ {533.333374} CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY0 {0.240} \
CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY1 {0.238} CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY2 {0.283} \
CONFIG.PCW_UIPARAM_DDR_BOARD_DELAY3 {0.284} CONFIG.PCW_UIPARAM_DDR_CLOCK_0_LENGTH_MM {33.621} \
CONFIG.PCW_UIPARAM_DDR_CLOCK_1_LENGTH_MM {33.621} CONFIG.PCW_UIPARAM_DDR_CLOCK_2_LENGTH_MM {48.166} \
CONFIG.PCW_UIPARAM_DDR_CLOCK_3_LENGTH_MM {48.166} CONFIG.PCW_UIPARAM_DDR_DQS_0_LENGTH_MM {38.200} \
CONFIG.PCW_UIPARAM_DDR_DQS_1_LENGTH_MM {38.692} CONFIG.PCW_UIPARAM_DDR_DQS_2_LENGTH_MM {38.778} \
CONFIG.PCW_UIPARAM_DDR_DQS_3_LENGTH_MM {38.635} CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_0 {-0.036} \
CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_1 {-0.036} CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_2 {0.058} \
CONFIG.PCW_UIPARAM_DDR_DQS_TO_CLK_DELAY_3 {0.057} CONFIG.PCW_UIPARAM_DDR_DQ_0_LENGTH_MM {38.671} \
CONFIG.PCW_UIPARAM_DDR_DQ_1_LENGTH_MM {38.635} CONFIG.PCW_UIPARAM_DDR_DQ_2_LENGTH_MM {38.671} \
CONFIG.PCW_UIPARAM_DDR_DQ_3_LENGTH_MM {38.679} CONFIG.PCW_UIPARAM_DDR_PARTNO {MT41K256M16 RE-125} \
CONFIG.PCW_UIPARAM_DDR_TRAIN_DATA_EYE {1} CONFIG.PCW_UIPARAM_DDR_TRAIN_READ_GATE {1} \
CONFIG.PCW_UIPARAM_DDR_TRAIN_WRITE_LEVEL {1} CONFIG.PCW_UIPARAM_DDR_USE_INTERNAL_VREF {1} \
CONFIG.PCW_USB0_PERIPHERAL_ENABLE {0} CONFIG.PCW_USE_FABRIC_INTERRUPT {1} \
CONFIG.PCW_USE_M_AXI_GP0 {1} CONFIG.PCW_USE_M_AXI_GP1 {0} \
CONFIG.PCW_USE_S_AXI_GP0 {0} CONFIG.preset {Default} \
 ] $processing_system7_0

  # Create interface connections
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins axi_interconnect_0/S00_AXI] [get_bd_intf_pins processing_system7_0/M_AXI_GP0]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_ports M00_AXI] [get_bd_intf_pins axi_interconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M01_AXI [get_bd_intf_pins axi_interconnect_0/M01_AXI] [get_bd_intf_pins panda_pcap_0/S00_AXI]
  connect_bd_intf_net -intf_net processing_system7_0_DDR [get_bd_intf_ports DDR] [get_bd_intf_pins processing_system7_0/DDR]
  connect_bd_intf_net -intf_net processing_system7_0_FIXED_IO [get_bd_intf_ports FIXED_IO] [get_bd_intf_pins processing_system7_0/FIXED_IO]

  # Create port connections
  connect_bd_net -net c_counter_binary_0_Q [get_bd_ports FCLK_LEDS] [get_bd_pins c_counter_binary_0/Q] [get_bd_pins ila_0/probe0]
  connect_bd_net -net panda_pcap_0_irq [get_bd_pins panda_pcap_0/irq] [get_bd_pins processing_system7_0/IRQ_F2P]
  connect_bd_net -net proc_sys_reset_0_interconnect_aresetn [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins proc_sys_reset_0/interconnect_aresetn]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_ports FCLK_RESET0_N] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins axi_interconnect_0/M01_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins panda_pcap_0/s00_axi_aresetn] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
  connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_ports FCLK_CLK0] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/M01_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins c_counter_binary_0/CLK] [get_bd_pins ila_0/clk] [get_bd_pins panda_pcap_0/s00_axi_aclk] [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK]
  connect_bd_net -net processing_system7_0_FCLK_RESET0_N [get_bd_pins proc_sys_reset_0/ext_reset_in] [get_bd_pins processing_system7_0/FCLK_RESET0_N]

  # Create address segments
  create_bd_addr_seg -range 0x10000 -offset 0x43C10000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs panda_pcap_0/S00_AXI/S00_AXI_reg] SEG_panda_pcap_0_S00_AXI_reg
  create_bd_addr_seg -range 0x10000 -offset 0x43C00000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs M00_AXI/Reg] SEG_panda_ps_Reg
  

  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


