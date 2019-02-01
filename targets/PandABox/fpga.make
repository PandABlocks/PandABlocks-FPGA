#
# PandA FPGA/SoC Makefile Builds:
#
#####################################################################

RUNVIVADO = source $(VIVADO) && vivado

#####################################################################
# Project related files and directories

AUTOGEN  = $(BUILD_DIR)/../autogen
SLOW_FPGA_BUILD_DIR = $(BUILD_DIR)/../SlowFPGA
IP_CORES = $(IP_DIR)
PS_CORE  = $(BUILD_DIR)/panda_ps/panda_ps.srcs/sources_1/bd/panda_ps/hdl/panda_ps.vhd

VERSION_FILE = $(AUTOGEN)/hdl/version.vhd

SDK_EXPORT = $(BUILD_DIR)/panda_ps/panda_ps.sdk
HWDEF = $(BUILD_DIR)/panda_ps/panda_ps_wrapper.hdf

IP_BUILD_SCR = $(TARGET_DIR)/scripts/build_ip.tcl
PS_BUILD_SCR = $(TARGET_DIR)/scripts/build_ps.tcl
PS_CONFIG_SCR = $(TARGET_DIR)/bd/panda_ps.tcl
TOP_BUILD_SCR = $(TARGET_DIR)/scripts/build_top.tcl
XSDK_BUILD_SCR = $(TARGET_DIR)/scripts/build_xsdk.tcl

DEVTREE_TAG = xilinx-v$(VIVADO_VER)
DEVTREE_NAME = device-tree-xlnx-$(DEVTREE_TAG)
DEVTREE_BSP = $(BUILD_DIR)/bsp/
DEVTREE_DTB = $(IMAGE_DIR)/devicetree.dtb
FSBL = $(IMAGE_DIR)/fsbl.elf

IMAGE_DIR=$(BUILD_DIR)/boot_images

#####################################################################
# BUILD TARGETS includes HW and SW
fpga-all: fpga-bits ps_boot
fpga-bits: slow_fpga carrier_fpga
carrier_ip: $(IP_CORES)
ps_core: $(PS_CORE)
ps_boot: devicetree fsbl
devicetree : $(DEVTREE_DTB)
fsbl : $(FSBL)
.PHONY: fpga-all fpga-bits carrier_ip ps_core ps_boot devicetree fsbl

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

$(IP_CORES) : $(IP_BUILD_SCR)
	$(RUNVIVADO) -mode $(DEP_MODE) -source $< \
	  -tclargs $(TARGET_DIR) $(IP_DIR) $(DEP_MODE)

$(PS_CORE) : $(PS_BUILD_SCR) $(PS_CONFIG_SCR)
	$(RUNVIVADO) -mode $(DEP_MODE) -source $< \
	    -tclargs $(TARGET_DIR) $(BUILD_DIR) $(DEP_MODE)

carrier_fpga : $(TOP_BUILD_SCR) VERSION $(IP_CORES) $(PS_CORE)
	$(RUNVIVADO) -mode $(TOP_MODE) -source $< \
	    -tclargs $(TOP) \
	    -tclargs $(TARGET_DIR) \
	    -tclargs $(BUILD_DIR) \
	    -tclargs $(AUTOGEN) \
	    -tclargs $(IP_DIR) \
	    -tclargs $(TOP_MODE)
.PHONY: carrier_fpga

###########################################################
# Build SlowFPGA Firmware target

slow_fpga: $(TARGET_DIR)/SlowFPGA/SlowFPGA.make VERSION $(TOP)/tools/virtexHex2Bin
	mkdir -p $(SLOW_FPGA_BUILD_DIR)
	echo building SlowFPGA
	source $(ISE)  &&  \
	  $(MAKE) -C $(SLOW_FPGA_BUILD_DIR) -f $< \
	  TOP=$(TOP) SRC_DIR=$(TARGET_DIR)/SlowFPGA \
	  BUILD_DIR=$(SLOW_FPGA_BUILD_DIR) mcs
.PHONY: slow_fpga

$(TOP)/tools/virtexHex2Bin: $(TOP)/tools/virtexHex2Bin.c
	gcc -o $@ $<

################################################################
# Build PS Boot targets

$(DEVTREE_DTB): $(SDK_EXPORT)
	cp $(TARGET_DIR)/configs/device-tree/$(DEVTREE_TAG)/pzed-z7030/system-top.dts \
	  $</device_tree_bsp_0/
	sed -i '/dts-v1/d' $</device_tree_bsp_0/system.dts
	@echo "Building DEVICE TREE blob ..."
	$(TARGET_DIR)/configs/linux-xlnx/scripts/dtc -f -I dts -O dtb -o $@ \
	  $</device_tree_bsp_0/system-top.dts

$(FSBL): $(SDK_EXPORT)
	cp $</fsbl/Release/fsbl.elf $@

$(SDK_EXPORT): $(XSDK_BUILD_SCR) $(HWDEF) $(DEVTREE_BSP)/$(DEVTREE_NAME) | $(IMAGE_DIR)
	rm -rf $@
	source $(VIVADO) && xsdk -batch -source $<

$(HWDEF): $(PS_CORE)

$(DEVTREE_BSP)/$(DEVTREE_NAME) : 
	unzip $(TAR_REPO)/$(DEVTREE_NAME).zip -d $(DEVTREE_BSP)

$(IMAGE_DIR) : 
	mkdir $(IMAGE_DIR)

sw_clean:
	rm -rf $(SDK_EXPORT)
	rm -rf $(IMAGE_DIR)/*

dts: $(DEVTREE_DTB)
	$(TARGET_DIR)/configs/linux-xlnx/scripts/dtc -f -I dtb -O dts -o $(IMAGE_DIR)/devicetree.dts $<

.PHONY: sw_clean dts

