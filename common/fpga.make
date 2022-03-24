#
# PandA FPGA/SoC Makefile Builds:
#
#####################################################################

# Some definitions of source file checksums to try and ensure repeatability of
# builds.  These releases are downloaded (as .tar.gz files) from:
#      https://github.com/Xilinx/u-boot-xlnx
#      https://github.com/Xilinx/linux-xlnx
# Note: if these files have been downloaded through the releases directory then
# they need to be renamed with the appropriate {u-boot,linux}-xlnx- prefix so
# that the file name and contents match.
MD5_SUM_device-tree-xlnx-xilinx-v2020.2 = c30a25d475c21fe4d9913b2df6aab692
MD5_SUM_u-boot-xlnx-xilinx-v2020.2 = 6881a6b9f465f714e64c1398630287db
MD5_SUM_arm-trusted-firmware-xilinx-v2020.2 = 0fd3ddbd76c27040e6ce848c9ef9c1f3
# The dtc source is obtained from https://git.kernel.org/pub/scm/utils/dtc/dtc.git
MD5_SUM_dtc-1.6.1 = 19eef37196e99b659c402a29aac5ba59

# By default use the same tagged version of the sources as the build tools.
# To use a different version edit the variable below, and include MD5_SUM above.
DEVTREE_TAG = xilinx-v$(VIVADO_VER)
U_BOOT_TAG = xilinx-v$(VIVADO_VER)
ATF_TAG = xilinx-v$(VIVADO_VER)
DTC_TAG = 1.6.1

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
FPGA_BIN_FILE = $(BUILD_DIR)/panda_top.bin

VERSION_FILE = $(AUTOGEN)/hdl/version.vhd

# target_incl.make needs to be included after the VERSION_FILE variable is defined otherwise
# make does not work out the dependencies properly. I don't understand why exactly!
-include $(TARGET_DIR)/target_incl.make

SDK_EXPORT = $(PS_DIR)/panda_ps.sdk
HWDEF = $(PS_DIR)/panda_ps.xsa

IP_BUILD_SCR = $(TOP)/common/scripts/build_ip.tcl
PS_BUILD_SCR = $(TOP)/common/scripts/build_ps.tcl
PS_CONFIG_SCR = $(TARGET_DIR)/bd/panda_ps.tcl
TOP_BUILD_SCR = $(TOP)/common/scripts/build_top.tcl
BOOT_BUILD_SCR = $(TOP)/common/scripts/build_boot.tcl

TGT_INCL_SCR = $(TARGET_DIR)/target_incl.tcl

SRC_ROOT = $(TGT_BUILD_DIR)/../../src

DEVTREE_NAME = device-tree-xlnx-$(DEVTREE_TAG)
DEVTREE_SRC = $(SRC_ROOT)/$(DEVTREE_NAME)
DTC_SRC = $(SRC_ROOT)/dtc-$(DTC_TAG)
DEVTREE_DTC = $(DTC_SRC)/dtc
TARGET_DTS = $(TARGET_DIR)/target-top.dts
DEVTREE_DTB = $(IMAGE_DIR)/devicetree.dtb
DEVTREE_DTS = $(SDK_EXPORT)/dts
FSBL = $(SDK_EXPORT)/fsbl/executable.elf
PMUFW = $(SDK_EXPORT)/pmufw/executable.elf

U_BOOT_NAME = u-boot-xlnx-$(U_BOOT_TAG)
U_BOOT_SRC = $(SRC_ROOT)/$(U_BOOT_NAME)

BOOT_BUILD = $(TGT_BUILD_DIR)/boot_build
U_BOOT_BUILD = $(BOOT_BUILD)/u-boot
U_BOOT_ELF = $(U_BOOT_BUILD)/u-boot.elf

ATF_NAME = arm-trusted-firmware-$(ATF_TAG)
ATF_SRC = $(SRC_ROOT)/$(ATF_NAME)
ATF_BUILD = $(BOOT_BUILD)/atf
ATF_ELF = $(ATF_BUILD)/build/zynqmp/release/bl31/bl31.elf

IMAGE_DIR=$(TGT_BUILD_DIR)/boot
    
# ------------------------------------------------------------------------------
# Helper code lifted from rootfs and other miscellaneous functions

# Use the rootfs extraction tool to decompress our source trees.
EXTRACT_FILE = $(ROOTFS_TOP)/scripts/extract-tar $(SRC_ROOT) $1 $2 $(TAR_FILES)


#####################################################################
# BUILD TARGETS includes HW and SW
fpga-all: fpga-bit boot
fpga-bit: carrier_fpga
carrier_ip: $(IP_DIR)/IP_BUILD_SUCCESS
ps_core: $(PS_CORE)
devicetree : $(DEVTREE_DTB)
fsbl : $(FSBL)
boot : $(IMAGE_DIR)/boot.bin $(DEVTREE_DTB)
u-boot: $(U_BOOT_ELF)
atf: $(ATF_ELF)
dtc: $(DEVTREE_DTC)
.PHONY: fpga-all fpga-bit carrier_ip ps_core boot devicetree fsbl u-boot atf dtc

#####################################################################
# Compiler variables needed for u-boot build and other complitation

include $(TARGET_DIR)/platform_incl.make

PLATFORM ?= zynq

ARCH=arm
ifeq ($(PLATFORM),zynq)
    CROSS_COMPILE=arm-linux-gnueabihf-
    UBOOT_CONFIG = xilinx_zynq_virt_defconfig
else ifeq ($(PLATFORM),zynqmp)
    CROSS_COMPILE=aarch64-linux-gnu-
    UBOOT_CONFIG = xilinx_zynqmp_virt_defconfig
else
    $$(error Unknown PLATFORM specified. Must be 'zynq' or 'zynqmp')
endif

#####################################################################
# Create VERSION_FILE

$(VERSION_FILE) : $(VER)
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
	  -tclargs $(TOP_MODE) \
	  -tclargs $(PLATFORM)

$(FPGA_BIN_FILE): $(CARRIER_FPGA_BIT)
	echo -e "all:\n{\n    $(CARRIER_FPGA_BIT)\n}\n" > bs.bif
	. $(VIVADO) && bootgen -image bs.bif -arch $(PLATFORM) -process_bitstream bin
	mv $(CARRIER_FPGA_BIT).bin $@

carrier_fpga : $(FPGA_BIN_FILE)
.PHONY: carrier_fpga

################################################################
# Build PS Boot targets

$(IMAGE_DIR)/boot.bin: $(BOOT_BUILD)/boot.bif
	. $(VIVADO) && bootgen -arch $(PLATFORM) -w -image $< -o $@

ifeq ($(PLATFORM),zynq)
$(BOOT_BUILD)/boot.bif: $(FSBL) $(U_BOOT_ELF)
	$(TOP)/common/scripts/make_bif_zynq.sh $@ $(FSBL) $(U_BOOT_ELF)

else ifeq ($(PLATFORM),zynqmp)
$(BOOT_BUILD)/boot.bif: $(FSBL) $(PMUFW) $(ATF_ELF) $(U_BOOT_ELF)
	$(TOP)/common/scripts/make_bif_zynqmp.sh \
            $@ $(FSBL) $(PMUFW) $(ATF_ELF) $(U_BOOT_ELF)

endif

# ------------------------------------------------------------------------------
# Building u-boot
#

MAKE_U_BOOT = $(MAKE) -C $(U_BOOT_SRC) \
  ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) KBUILD_OUTPUT=$(U_BOOT_BUILD)

$(U_BOOT_ELF): $(U_BOOT_SRC) $(DEVTREE_DTB)
	mkdir -p $(U_BOOT_BUILD)
	. $(VIVADO) && $(MAKE_U_BOOT) distclean
	. $(VIVADO) && $(MAKE_U_BOOT) $(UBOOT_CONFIG)
ifdef UBOOT_USE_EXT_DTB
	. $(VIVADO) && $(MAKE_U_BOOT) EXT_DTB=$(DEVTREE_DTB)
else	
	. $(VIVADO) && $(MAKE_U_BOOT) DEVICE_TREE=$(UBOOT_DTS)
endif


$(U_BOOT_SRC): | $(SRC_ROOT)
	$(call EXTRACT_FILE,$(U_BOOT_NAME).tar.gz,$(MD5_SUM_$(U_BOOT_NAME)))
	chmod -R a-w $(U_BOOT_SRC)

$(ATF_ELF): $(ATF_SRC)
	mkdir -p $(ATF_BUILD)
	cp -rf --no-preserve=mode $(ATF_SRC)/* $(ATF_BUILD)
	. $(VIVADO) && cd $(ATF_BUILD) && \
        $(MAKE) PLAT=$(PLATFORM) CROSS_COMPILE=$(CROSS_COMPILE) RESET_TO_BL31=1

$(ATF_SRC): | $(SRC_ROOT)
	$(call EXTRACT_FILE,$(ATF_NAME).tar.gz,$(MD5_SUM_$(ATF_NAME)))
	chmod -R a-w $(ATF_SRC)

$(SRC_ROOT):
	mkdir -p $(SRC_ROOT)

u-boot-src: $(U_BOOT_SRC)

.PHONY: u-boot-src
# -----------------------------------------------------------------------------------

$(DEVTREE_DTB): $(SDK_EXPORT) $(TARGET_DTS) $(DEVTREE_DTC)
	cp $(TARGET_DTS) $(DEVTREE_DTS)/
	sed -i '/dts-v1/d' $(DEVTREE_DTS)/system-top.dts
	gcc -I dts -E -nostdinc -undef -D__DTS__ -x assembler-with-cpp \
	  -o $(DEVTREE_DTS)/system-top.dts.tmp $(DEVTREE_DTS)/system-top.dts
	@echo "Building DEVICE TREE blob ..."
	$(DEVTREE_DTC) -f -I dts -O dtb -o $@ $(DEVTREE_DTS)/$(notdir $(TARGET_DTS))

$(DEVTREE_DTC): $(DTC_SRC)
	$(MAKE) -C $(SRC_ROOT)/dtc-$(DTC_TAG) NO_PYTHON=1

$(DTC_SRC): | $(SRC_ROOT)
	$(call EXTRACT_FILE,dtc-$(DTC_TAG).tar.gz,$(MD5_SUM_dtc-$(DTC_TAG)))

$(FSBL): $(SDK_EXPORT)

$(PMUFW): $(SDK_EXPORT)

$(SDK_EXPORT): $(BOOT_BUILD_SCR) $(PS_CORE) $(DEVTREE_SRC) | $(IMAGE_DIR)
	rm -rf $@
	. $(VIVADO) && xsct $< \
	    $(PLATFORM) $(HWDEF) $(DEVTREE_SRC) $@

xsct : $(SDK_EXPORT)
.PHONEY: xsct

$(DEVTREE_SRC) : | $(SRC_ROOT)
	$(call EXTRACT_FILE,$(DEVTREE_NAME).tar.gz,$(MD5_SUM_$(DEVTREE_NAME)))

$(IMAGE_DIR) : 
	mkdir $(IMAGE_DIR)

# Phony targets

dts: $(DEVTREE_DTB)
	$(DEVTREE_DTC) -f -I dtb -O dts -o $(IMAGE_DIR)/devicetree.dts $<

sw_clean:
	rm -rf $(SDK_EXPORT)
	rm -rf $(IMAGE_DIR)/*

ip_clean:
	rm -rf $(IP_DIR)

ps_clean:
	rm -rf $(PS_DIR)

.PHONY: dts sw_clean ip_clean ps_clean

