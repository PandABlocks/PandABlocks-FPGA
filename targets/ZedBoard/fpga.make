#
# PandA FPGA/SoC Makefile Builds:
#
#####################################################################

# Need bash for the source command in Xilinx settings64.sh
SHELL = /bin/bash

RUNVIVADO = . $(VIVADO) && vivado

#####################################################################
# Project related files and directories

BUILD_DIR = $(APP_BUILD_DIR)/FPGA
AUTOGEN  = $(APP_BUILD_DIR)/autogen
IP_DIR = $(TGT_BUILD_DIR)/ip_repo/IP_BUILD_SUCCEED
PS_DIR = $(TGT_BUILD_DIR)/panda_ps
PS_CORE  = $(PS_DIR)/panda_ps.srcs/sources_1/bd/panda_ps/panda_ps.bd

VERSION_FILE = $(AUTOGEN)/hdl/version.vhd

SDK_EXPORT = $(PS_DIR)/panda_ps.sdk
HWDEF = $(PS_DIR)/panda_ps.srcs/sources_1/bd/panda_ps/hdl/panda_ps.hdf

IP_BUILD_SCR = $(TARGET_DIR)/scripts/build_ip.tcl
PS_BUILD_SCR = $(TARGET_DIR)/scripts/build_ps.tcl
PS_CONFIG_SCR = $(TARGET_DIR)/bd/panda_ps.tcl
TOP_BUILD_SCR = $(TARGET_DIR)/scripts/build_top.tcl
XSDK_BUILD_SCR = $(TOP)/common/scripts/build_xsdk.tcl
UBOOT_BUILD_SCR = $(TOP)/common/u-boot/u-boot.make

# Manually set the device tree sources verison to v2015.1 to match the
# Kernel and uboot version in rootfs repo
#DEVTREE_TAG = xilinx-v$(VIVADO_VER)
#DEVTREE_NAME = device-tree-xlnx-$(DEVTREE_TAG)
DEVTREE_NAME = device-tree-xlnx-xilinx-v2015.1
DEVTREE_BSP = $(TGT_BUILD_DIR)/../../src
DEVTREE_SRC = $(DEVTREE_BSP)/$(DEVTREE_NAME)
DEVTREE_DTC = $(TOP)/common/configs/linux-xlnx/scripts/dtc
DEVTREE_DTB = $(IMAGE_DIR)/devicetree.dtb
FSBL = $(SDK_EXPORT)/fsbl/Release/fsbl.elf

BOOT_BUILD = $(TGT_BUILD_DIR)/boot_build
U_BOOT_BUILD = $(BOOT_BUILD)/u-boot
U_BOOT_ELF = $(U_BOOT_BUILD)/u-boot.elf

IMAGE_DIR=$(TGT_BUILD_DIR)/boot

#####################################################################
# BUILD TARGETS includes HW and SW
fpga-all: fpga-bits ps_boot
fpga-bits: carrier_fpga
carrier_ip: $(IP_DIR)
ps_core: $(PS_CORE)
devicetree : $(DEVTREE_DTB)
fsbl : $(FSBL)
boot : $(IMAGE_DIR)/boot.bin
u-boot: $(U_BOOT_ELF)
.PHONY: fpga-all fpga-bits carrier_ip ps_core ps_boot devicetree fsbl u-boot

#####################################################################
# HW Projects Build

VERSION :
	rm -f $(VERSION_FILE)
	echo 'library ieee;' >> $(VERSION_FILE)
	echo 'use ieee.std_logic_1164.all;' >> $(VERSION_FILE)
	echo 'package version is' >> $(VERSION_FILE)
	echo -n 'constant FPGA_VERSION: std_logic_vector(31 downto 0)' \ >> $(VERSION_FILE)
	echo ' := X"$(VERSION)";' >> $(VERSION_FILE)
	echo -n 'constant FPGA_BUILD: std_logic_vector(31 downto 0)' \ >> $(VERSION_FILE)
	echo ' := X"$(SHA)";' >> $(VERSION_FILE)
	echo 'end version;' >> $(VERSION_FILE)
.PHONY: VERSION
###########################################################
# Build Zynq Firmware targets

$(IP_DIR) : $(IP_BUILD_SCR)
	$(RUNVIVADO) -mode $(DEP_MODE) -source $< \
	  -log $(TGT_BUILD_DIR)/build_ip.log -nojournal \
	  -tclargs $(TOP) $(TARGET_DIR) $(IP_DIR) $(DEP_MODE)
	touch $@


$(PS_CORE) : $(PS_BUILD_SCR) $(PS_CONFIG_SCR)
	$(RUNVIVADO) -mode $(DEP_MODE) -source $< \
	  -log $(TGT_BUILD_DIR)/build_ps.log -nojournal \
	  -tclargs $(TOP) $(TARGET_DIR) $(PS_DIR) $@ $(DEP_MODE)

carrier_fpga : $(TOP_BUILD_SCR) VERSION $(IP_DIR) $(PS_CORE)
	$(RUNVIVADO) -mode $(TOP_MODE) -source $< \
	  -log $(BUILD_DIR)/build_top.log -nojournal \
	  -tclargs $(TOP) \
	  -tclargs $(TARGET_DIR) \
	  -tclargs $(BUILD_DIR) \
	  -tclargs $(AUTOGEN) \
	  -tclargs $(IP_DIR) \
	  -tclargs $(PS_CORE) \
	  -tclargs $(TOP_MODE)
.PHONY: carrier_fpga

################################################################
# Build PS Boot targets

$(IMAGE_DIR)/boot.bin $(IMAGE_DIR)/uEnv.txt: $(BOOT_BUILD)/boot.bif
	. $(VIVADO) && bootgen -w -image $< -o i $(IMAGE_DIR)/boot.bin
	cp $(TOP)/common/u-boot/uEnv.txt $(IMAGE_DIR)/uEnv.txt

$(BOOT_BUILD)/boot.bif: $(FSBL) $(U_BOOT_ELF)
	$(TOP)/common/scripts/make_boot.bif $@ $(FSBL) $(U_BOOT_ELF)

$(U_BOOT_ELF): $(UBOOT_BUILD_SCR) $(DEVTREE_DTB)
	$(MAKE) -f $< TGT_DIR=$(TARGET_DIR) U_BOOT_BUILD=$(U_BOOT_BUILD) \
	  SRC_ROOT=$(TGT_BUILD_DIR)/../../src DEVICE_TREE_DTB=$(DEVTREE_DTB) \
	  TOP=$(TOP) u-boot
	ln -sf $(U_BOOT_BUILD)/u-boot $@

$(DEVTREE_DTB): $(SDK_EXPORT)
	cp $(TARGET_DIR)/configs/system-top.dts \
	  $</device_tree_bsp_0/
	sed -i '/dts-v1/d' $</device_tree_bsp_0/system.dts
	@echo "Building DEVICE TREE blob ..."
	$(DEVTREE_DTC) -f -I dts -O dtb -o $@ \
	  $</device_tree_bsp_0/system-top.dts

$(FSBL): $(SDK_EXPORT)

$(SDK_EXPORT): $(XSDK_BUILD_SCR) $(HWDEF) $(DEVTREE_SRC) | $(IMAGE_DIR)
	rm -rf $@
	source $(VIVADO) && xsdk -batch -source $< \
	    $(SDK_EXPORT) $(HWDEF) $(DEVTREE_SRC)

$(HWDEF): $(PS_CORE)
	cp $(basename $@).hwdef $@

$(DEVTREE_SRC) : 
	mkdir -p $(DEVTREE_BSP)
	unzip $(TAR_REPO)/$(DEVTREE_NAME).zip -d $(DEVTREE_BSP)

$(IMAGE_DIR) : 
	mkdir $(IMAGE_DIR)

# Phony targets

dts: $(DEVTREE_DTB)
	$(DEVTREE_DTC) -f -I dtb -O dts -o $(IMAGE_DIR)/devicetree.dts $<

sw_clean:
	rm -rf $(SDK_EXPORT)
	rm -rf $(IMAGE_DIR)/*

.PHONY: dts sw_clean

