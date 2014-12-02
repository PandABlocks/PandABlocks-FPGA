#
# PandA FPGA/SoC Makefile Builds:
#
#  Step 1. Zynq PS Block design and exports HDF file
#  Step 2. Zynq Top level design bit file
#  Step 3. Gets device-tree BSP sources (remote git or local tarball)
#  Step 4. Generates xsdk project (using xml configuration file)
#  Step 5. Generates fsbl elf, and device-tree dts files
#  Step 6. Generates devicetree.dtb file and copies to TFTP server

#####################################################################
# Modify accordingly following 3 lines
# Everything is build under $(PWD)/$(OUT_DIR)

VIVADO = source /dls_sw/FPGA/Xilinx/Vivado/2014.2/settings64.sh > /dev/null
BOARD = xilinx-zc706
OUT_DIR = output

#####################################################################
# Project related files (DON'T TOUCH)

PS_DIR   = $(OUT_DIR)/panda_ps/panda_ps.srcs
PS_CORE  = $(PS_DIR)/sources_1/bd/panda_ps/hdl/panda_ps.vhd
FPGA_BIT = $(OUT_DIR)/panda_top.bit
SDK_EXPORT = $(OUT_DIR)/panda_ps/panda_ps.sdk
FSBL_ELF   = $(SDK_EXPORT)/fsbl/Debug/fsbl.elf
DEVTREE_DTS = $(SDK_EXPORT)/device_tree_bsp_0/system.dts
DEVTREE_DTB = $(SDK_EXPORT)/device_tree_bsp_0/devicetree.dtb

#####################################################################
# BUILD TARGETS includes HW and SW

all: $(OUT_DIR) $(PS_CORE) $(FPGA_BIT) $(FSBL_ELF) $(DEVTREE_DTB)

#####################################################################
# HW Projects Build

clean :
	rm -rf $(OUT_DIR)

$(OUT_DIR) :
	mkdir $(OUT_DIR)

# STEP-1 ##########################################################
#
$(PS_CORE) :
	cd $(OUT_DIR) && \
	    $(VIVADO) && vivado -mode batch -source ../buid_ps.tcl

# STEP-2 ##########################################################
#
$(FPGA_BIT):
	cd $(OUT_DIR) && \
	    $(VIVADO) && vivado -mode batch -source ../buid_top.tcl


#####################################################################
# SW Projects Build
#
# Build HW Platform, FSBL and Device Tree
#

#########################################################################
# DEVICE_TREE:
# We should get the Device-Tree BSP sources either from remote git-repository,
# or local tar-ball repository

SOURCES = tarball
#SOURCES = git

DEVTREE_TAG = xilinx-v2014.2.01
DEVTREE_NAME = device-tree-xlnx-$(DEVTREE_TAG)
TAR_REPO = /dls_sw/FPGA/Xilinx/OSLinux/tar-balls

# Device-tree BSP will be extracted in $(DEVTREE_BSP) as below
DEVTREE_BSP = $(PWD)/output/bsp/

$(DEVTREE_BSP)/$(DEVTREE_NAME) :
ifeq ($(SOURCES), git)
	git clone -b $(DEVTREE_TAG) $(DEVTREE_REPO) $(DEVTREE_BSP)
endif

ifeq ($(SOURCES), tarball)
	unzip $(TAR_REPO)/$(DEVTREE_NAME).zip -d $(DEVTREE_BSP)
endif

#########################################################################
# Delete everything but the HDF file

xsdk_clean:
	rm -rf $(SDK_EXPORT)/.metadata
	rm -rf $(SDK_EXPORT)/hw_platform_0
	rm -rf $(SDK_EXPORT)/fsbl*
	rm -rf $(SDK_EXPORT)/device*
	rm -rf $(DEVTREE_BSP)/$(DEVTREE_NAME)

# Step-3 ###############################################################
#
# Get Device-Tree BSP
# 1./ device-tree repository to local xsdk workspace,
# 2./ Create xsdk project based on sdkproj.xml file
#
# sdkproj.xml sets-up
#  - hardware, device-tree bsp and fsbl projects

# Step-4 ###############################################################
# Generate XSDK projects in panda.sdk workspace

XSDK_CONFIG_FILE = configs/sdkproj.xml

xsdk_wspace: xsdk_clean $(DEVTREE_BSP)/$(DEVTREE_NAME)
	$(VIVADO) && \
	    xsdk -wait -eclipseargs -nosplash -application com.xilinx.sdk.sw.AddSwRepositoryApp "$(DEVTREE_BSP)" -data $(SDK_EXPORT) && \
	    xsdk -wait -script $(XSDK_CONFIG_FILE) -workspace $(SDK_EXPORT)

# Step-5 ###############################################################
# Build all XSDK projects to generate fsbl.elf and system.dts

$(FSBL_ELF): xsdk_wspace
	$(VIVADO) && \
	    xsdk -wait -eclipseargs -nosplash -application org.eclipse.cdt.managedbuilder.core.headlessbuild -build all -data output/panda_ps/panda_ps.sdk/ -vmargs -Dorg.eclipse.cdt.core.console=org.eclipse.cdt.core.systemConsole

# Step-6 ###############################################################
# Generate the DTB file after device-tree bsp generated
#
# A top-level board-specific dts file is stored (stolen from petalinux)
# in configs directory which includes Xsdk generated *.dtsi files.
#

DTS_CONFIG_FILE = $(PWD)/configs/device-tree/$(DEVTREE_TAG)/$(BOARD)/system-top.dts
DTS_BUILD_DIR = $(SDK_EXPORT)/device_tree_bsp_0
DTS_TOP_FILE = $(DTS_BUILD_DIR)/system-top.dts

$(DTS_TOP_FILE): $(DEVTREE_DTS)
	cp $(DTS_CONFIG_FILE) $@

$(DEVTREE_DTB) : $(DTS_TOP_FILE)
	$(PWD)/configs/linux-xlnx/scripts/dtc -f -I dts -O dtb -o $(DEVTREE_DTB) $(DTS_BUILD_DIR)/system-top.dts
	scp $(DEVTREE_DTB) iu42@serv2:/tftpboot
