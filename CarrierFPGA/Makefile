#
# PandA FPGA/SoC Makefile Builds:
#
#####################################################################
GIT_VERSION = $(shell git describe --abbrev=8 --always)

RUNVIVADO = source $(VIVADO) && vivado

include $(TOP)/VERSION

SRCDIR = $(TOP)/CarrierFPGA
HDLDIR = $(TOP)/CarrierFPGA/src/hdl

#####################################################################
# Project related files (DON'T TOUCH)

PS_DIR   = $(BUILD_DIR)/panda_ps/panda_ps.srcs
IP_CORES = $(BUILD_DIR)/ip_repo
PS_CORE  = $(PS_DIR)/sources_1/bd/panda_ps/hdl/panda_ps.vhd
FPGA_BIT = $(BUILD_DIR)/panda_top.bit

VERSION_FILE = $(BUILD_DIR)/autogen/panda_version.vhd

#####################################################################
# BUILD TARGETS includes HW and SW
default : fpga
fpga : panda_top.bit
.PHONY: default fpga VERSION

#####################################################################
# HW Projects Build

VERSION :
	rm -f $(VERSION_FILE)
	echo 'library ieee;' > $(VERSION_FILE)
	echo 'use ieee.std_logic_1164.all;' >> $(VERSION_FILE)
	echo 'package panda_version is' >> $(VERSION_FILE)
	echo -n 'constant FPGA_VERSION: std_logic_vector(31 downto 0)' \ >> $(VERSION_FILE)
	echo ' := X"$(FIRMWARE)";' >> $(VERSION_FILE)
	echo 'end panda_version;' >> $(VERSION_FILE)

###########################################################
# Build FPGA

$(IP_CORES) :
	$(RUNVIVADO) -mode batch -source $(TARGET_DIR)/scripts/build_ips.tcl \
	    -tclargs $(TARGET_DIR) -tclargs $(BUILD_DIR)

$(PS_CORE) :
	$(RUNVIVADO) -mode batch -source $(TARGET_DIR)/scripts/build_ps.tcl \
	    -tclargs $(TARGET_DIR) -tclargs $(BUILD_DIR)

#panda_top.bit : VERSION $(IP_CORES) $(PS_CORE)
panda_top.bit : VERSION
	$(RUNVIVADO) -mode batch -source $(TARGET_DIR)/scripts/build_top.tcl \
	    -tclargs $(TOP) \
	    -tclargs $(TARGET_DIR) \
	    -tclargs $(BUILD_DIR) \
	    -tclargs $(FMC_DESIGN) \
	    -tclargs $(SFP_DESIGN) \
