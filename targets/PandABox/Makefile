#
# PandA FPGA/SoC Makefile Builds:
#
#####################################################################

# Need bash for the source command in Xilinx settings64.sh
SHELL = /bin/bash

RUNVIVADO = . $(VIVADO) && vivado

include $(TOP)/VERSION

#####################################################################
# Project related files (DON'T TOUCH)

AUTOGEN  = $(BUILD_DIR)/../autogen
PS_DIR   = $(BUILD_DIR)/panda_ps/panda_ps.srcs
IP_CORES = $(IP_DIR)
PS_CORE  = $(PS_DIR)/sources_1/bd/panda_ps/hdl/panda_ps.vhd
FPGA_BIT = $(BUILD_DIR)/panda_top.bit

VERSION_FILE = $(AUTOGEN)/hdl/panda_version.vhd

#####################################################################
# BUILD TARGETS includes HW and SW
default : carrier-fpga
carrier-fpga : panda_top.bit
carrier-ip: $(IP_CORES)
.PHONY: default carrier-fpga carrier-ip VERSION

#####################################################################
# HW Projects Build

VERSION :
	rm -f $(VERSION_FILE)
	echo 'library ieee;' >> $(VERSION_FILE)
	echo 'use ieee.std_logic_1164.all;' >> $(VERSION_FILE)
	echo 'package panda_version is' >> $(VERSION_FILE)
	echo -n 'constant FPGA_VERSION: std_logic_vector(31 downto 0)' \ >> $(VERSION_FILE)
	echo ' := X"$(VERSION)";' >> $(VERSION_FILE)
	echo -n 'constant FPGA_BUILD: std_logic_vector(31 downto 0)' \ >> $(VERSION_FILE)
	echo ' := X"$(SHA)";' >> $(VERSION_FILE)
	echo 'end panda_version;' >> $(VERSION_FILE)

###########################################################
# Build FPGA

$(IP_CORES) :
	$(RUNVIVADO) -mode batch -source $(TARGET_DIR)/scripts/build_ips.tcl \
	  -log build_ips.log -nojournal \
	  -tclargs $(TARGET_DIR) -tclargs $(IP_DIR)

$(PS_CORE) :
	$(RUNVIVADO) -mode batch -source $(TARGET_DIR)/scripts/build_ps.tcl \
	  -log build_ps.log -nojournal \
	  -tclargs $(TARGET_DIR) -tclargs $(BUILD_DIR)

panda_top.bit : VERSION $(IP_CORES) $(PS_CORE)
	$(RUNVIVADO) -mode batch -source $(TARGET_DIR)/scripts/build_top.tcl \
	  -log build_top.log -nojournal \
	  -tclargs $(TOP) \
	  -tclargs $(TARGET_DIR) \
	  -tclargs $(BUILD_DIR) \
	  -tclargs $(AUTOGEN) \
	  -tclargs $(IP_DIR)

