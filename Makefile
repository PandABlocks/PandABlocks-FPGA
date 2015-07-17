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
# Modify accordingly following lines
# Everything is build under $(PWD)/$(OUT_DIR)
TAR_REPO = /dls_sw/FPGA/Xilinx/OSLinux/tar-balls
VIVADO_VER = 2015.1
BOARD = pzed-z7030
OUT_DIR = output
IMAGE_DIR = images

VIVADO = source /dls_sw/FPGA/Xilinx/Vivado/$(VIVADO_VER)/settings64.sh > /dev/null

#####################################################################
# Project related files (DON'T TOUCH)

PS_DIR   = $(OUT_DIR)/panda_ps/panda_ps.srcs
PS_CORE  = $(PS_DIR)/sources_1/bd/panda_ps/hdl/panda_ps.vhd
FPGA_BIT = $(OUT_DIR)/panda_top.bit
SDK_EXPORT = $(OUT_DIR)/panda_ps/panda_ps.sdk
FSBL_ELF   = $(SDK_EXPORT)/fsbl/Debug/fsbl.elf
DEVTREE_DTS = $(SDK_EXPORT)/device_tree_bsp_0/system.dts
DEVTREE_DTB = $(SDK_EXPORT)/device_tree_bsp_0/devicetree.dtb
BOOT_FILE = $(IMAGE_DIR)/boot.bin

#####################################################################
# BUILD TARGETS includes HW and SW

all: $(OUT_DIR) $(PS_CORE) $(FPGA_BIT) $(SDK_EXPORT) $(DEVTREE_DTB) $(BOOT_FILE)
devicetree: $(DEVTREE_DTB)
boot: $(BOOT_FILE)

#####################################################################
# HW Projects Build

clean :
	rm -rf $(OUT_DIR)

$(OUT_DIR) :
	mkdir $(OUT_DIR)

# STEP-1 ##########################################################
# Build PS Core Block Design

$(PS_CORE) :
	cd $(OUT_DIR) && \
	    $(VIVADO) && vivado -mode batch -source ../build_ps.tcl

# STEP-2 ##########################################################
# Build top-level design

$(FPGA_BIT):
	rm -rf $(OUT_DIR)/panda_top
	cd $(OUT_DIR) && \
	    $(VIVADO) && vivado -mode batch -source ../build_top.tcl
	scp $(FPGA_BIT) root@172.23.252.102:/mnt

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

DEVTREE_TAG = xilinx-v$(VIVADO_VER)
DEVTREE_NAME = device-tree-xlnx-$(DEVTREE_TAG)

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

sw_clean:
	rm -rf $(SDK_EXPORT)
	rm $(IMAGE_DIR)/*


# Step-4 ###############################################################
# Get device-tree repository into project
# Generate XSDK projects in panda.sdk workspace,
# Build all XSDK projects for FSBL and Device Tree

$(SDK_EXPORT): $(DEVTREE_BSP)/$(DEVTREE_NAME)
	$(VIVADO) && \
	    xsdk -batch build_xsdk.tcl


# Step-6 ###############################################################
# Generate the DTB file after device-tree bsp generated
#
# system-top.dts : Copied from local /configs, board specific
# system.dts     : XSDK generated, and included in system-top.dts
#

DTS_CONFIG_DIR = $(PWD)/configs/device-tree/$(DEVTREE_TAG)/$(BOARD)
DTS_CONFIG_FILE = $(DTS_CONFIG_DIR)/system-top.dts
DTS_BUILD_DIR = $(SDK_EXPORT)/device_tree_bsp_0
DTS_TOP_FILE = $(DTS_BUILD_DIR)/system-top.dts

$(DTS_TOP_FILE): $(DEVTREE_DTS)
	sed -i '/dts-v1/d' $(DEVTREE_DTS)
	sed -i "/fclk-enable/c\fclk-enable = <0xf>;" $(DEVTREE_DTS)
	cp $(DTS_CONFIG_FILE) $@

$(DEVTREE_DTB) : $(DTS_TOP_FILE)
	echo "Building DEVICE TREE..."
	$(PWD)/configs/linux-xlnx/scripts/dtc -f -I dts -O dtb -o $(DEVTREE_DTB) $(DTS_TOP_FILE)
# 	scp $(DEVTREE_DTB) iu42@serv2:/tftpboot

# Step-6 ###############################################################
# Save all image files
$(IMAGE_DIR):
	mkdir $(IMAGE_DIR)

$(BOOT_FILE) : $(IMAGE_DIR)
	$(VIVADO) && \
	    bootgen -w -image configs/boot.bif -o i $(IMAGE_DIR)/boot.bin
	cp ./output/panda_ps/panda_ps.sdk/fsbl/Release/fsbl.elf $(IMAGE_DIR)
	cp ./output/panda_top.bit $(IMAGE_DIR)

dts:
	$(PWD)/configs/linux-xlnx/scripts/dtc -f -I dtb -O dts -o devicetree.dts $(DEVTREE_DTB)

