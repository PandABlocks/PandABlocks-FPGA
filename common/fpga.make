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
IP_DIR = $(TGT_BUILD_DIR)/ip_repo
PS_DIR = $(TGT_BUILD_DIR)/panda_ps
PS_CORE  = $(PS_DIR)/panda_ps.srcs/sources_1/bd/panda_ps/panda_ps.bd
CARRIER_FPGA_BIT = $(BUILD_DIR)/panda_top.bit

VERSION_FILE = $(AUTOGEN)/hdl/version.vhd

# target_incl.make needs to be included after the VERSION_FILE variable is defined otherwise
# make does not work out the dependencies properly. I don't understand why exactly!
-include $(TARGET_DIR)/target_incl.make

SDK_EXPORT = $(PS_DIR)/panda_ps.sdk
HWDEF = $(PS_DIR)/panda_ps.srcs/sources_1/bd/panda_ps/hdl/panda_ps.hdf

IP_BUILD_SCR = $(TOP)/common/scripts/build_ip.tcl
PS_BUILD_SCR = $(TOP)/common/scripts/build_ps.tcl
PS_CONFIG_SCR = $(TARGET_DIR)/bd/panda_ps.tcl
TOP_BUILD_SCR = $(TOP)/common/scripts/build_top.tcl
XSDK_BUILD_SCR = $(TOP)/common/scripts/build_xsdk.tcl
UBOOT_BUILD_SCR = $(TOP)/common/u-boot/u-boot.make

TGT_INCL_SCR = $(TARGET_DIR)/target_incl.tcl

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

BITS_PREREQ += carrier_fpga

#####################################################################
# BUILD TARGETS includes HW and SW
fpga-all: fpga-bits boot
fpga-bits: $(BITS_PREREQ)
carrier_ip: $(IP_DIR)/IP_BUILD_SUCCESS
ps_core: $(PS_CORE)
devicetree : $(DEVTREE_DTB)
fsbl : $(FSBL)
boot : $(IMAGE_DIR)/boot.bin
u-boot: $(U_BOOT_ELF)
.PHONY: fpga-all fpga-bits carrier_ip ps_core boot devicetree fsbl u-boot

#####################################################################
# Compiler variables needed for u-boot build and other complitation

include $(TARGET_DIR)/platform_incl.make

## The following code is for future compatability with the Zynq Ultrascale+ MPSoC
## We need to specify different architecture and cross-compile toolchain for the 
## zynqmp platform, as well as u-boot config. It is commented out for the time being.
#
#PLATFORM ?= zynq
#
#ifeq($(PLATFORM),zynq)
#    ARCH=arm
#    # Use Linero (hard float) toolchain rather than CodeSourcery (soft float) toolchain?
#    CROSS_COMPILE=arm-linux-gnueabihf-
#    # From Vivado 2020 onwards we can use the common defconfig
#    #UBOOT_CONFIG = xilinx_zynq_virt_defconfig
#    # For ealier Vivado we can specify zc70x as a generic config, as we are only using it to build mkimage
#    UBOOT_CONFIG = zynq_zc70x_config
#else ifeq($(PLATFORM,zynqmp)
#    ARCH=aarch64
#    CROSS_COMPILE=aarch64-linux-gnu-
#    # From Vivado 2020 onwards we can use the common defconfig
#    #UBOOT_CONFIG = xilinx_zynqmp_virt_defconfig
#    # For earlier Vivado versions, we can try zcu102 as an initial guess for the relevant config.
#    UBOOT_CONFIG = xilinx_zynqmp_zcu102_rev1_0_defconfig
#else
#    $$(error Unknown PLATFORM specified. Must be 'zynq' or 'zynqmp')

CROSS_COMPILE = arm-xilinx-linux-gnueabi-
ARCH = arm

#####################################################################
# Create VERSION_FILE

$(VERSION_FILE) : $(PREV_VER)
	rm -f $(VERSION_FILE)
	echo 'library ieee;' >> $(VERSION_FILE)
	echo 'use ieee.std_logic_1164.all;' >> $(VERSION_FILE)
	echo 'package version is' >> $(VERSION_FILE)
	echo -n 'constant FPGA_VERSION: std_logic_vector(31 downto 0)' >> $(VERSION_FILE)
	echo ' := X"$(VERSION)";' >> $(VERSION_FILE)
	echo -n 'constant FPGA_BUILD: std_logic_vector(31 downto 0)' >> $(VERSION_FILE)
	echo ' := X"$(SHA)";' >> $(VERSION_FILE)
	echo 'end version;' >> $(VERSION_FILE)

###########################################################
# Build Zynq Firmware targets

$(IP_DIR)/IP_BUILD_SUCCESS : $(IP_BUILD_SCR) $(TGT_INCL_SCR)
	rm -f $@
	$(RUNVIVADO) -mode $(DEP_MODE) -source $< \
	  -log $(TGT_BUILD_DIR)/build_ip.log -nojournal \
	  -tclargs $(TOP) $(TARGET_DIR) $(IP_DIR) $(DEP_MODE)
	touch $@

$(PS_CORE) : $(PS_BUILD_SCR) $(PS_CONFIG_SCR) $(TGT_INCL_SCR)
	$(RUNVIVADO) -mode $(DEP_MODE) -source $< \
	  -log $(TGT_BUILD_DIR)/build_ps.log -nojournal \
	  -tclargs $(TOP) $(TARGET_DIR) $(PS_DIR) $@ $(DEP_MODE)

CARRIER_FPGA_DEPS += $(TOP_BUILD_SCR)
CARRIER_FPGA_DEPS += $(VERSION_FILE)
CARRIER_FPGA_DEPS += $(IP_DIR)/IP_BUILD_SUCCESS
CARRIER_FPGA_DEPS += $(PS_CORE)
CARRIER_FPGA_DEPS += $(TGT_INCL_SCR)

$(CARRIER_FPGA_BIT) : $(CARRIER_FPGA_DEPS)
	$(RUNVIVADO) -mode $(TOP_MODE) -source $< \
	  -log $(BUILD_DIR)/build_top.log -nojournal \
	  -tclargs $(TOP) \
	  -tclargs $(TARGET_DIR) \
	  -tclargs $(BUILD_DIR) \
	  -tclargs $(AUTOGEN) \
	  -tclargs $(IP_DIR) \
	  -tclargs $(PS_CORE) \
	  -tclargs $(TOP_MODE)

carrier_fpga : $(CARRIER_FPGA_BIT)
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
      UBOOT_CONFIG=$(UBOOT_CONFIG) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=$(ARCH) \
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
	. $(VIVADO) && xsdk -batch -source $< \
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

