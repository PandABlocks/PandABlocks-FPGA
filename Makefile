#
# PandA FPGA/SoC Makefile
#
# Creates project build directories under $(OUT_DIR)/
#

VIVADO=source /dls_sw/FPGA/Xilinx/Vivado/2014.2/settings64.sh > /dev/null

OUT_DIR = output
PS_DIR  = $(OUT_DIR)/panda_ps/panda_ps.srcs
SDK_EXPORT = $(OUT_DIR)/panda_ps/panda_ps.sdk/

PS_CORE  = $(PS_DIR)/sources_1/bd/panda_ps/hdl/panda_ps.vhd
FPGA_BIT = $(OUT_DIR)/panda_top.bit
FSBL_ELF =$(SDK_EXPORT)/zynq_fsbl/Debug/zynq_fsbl.elf
DEV_TREE =$(SDK_EXPORT)/device-tree_bsp_0/ps7_cortexa9_0/libsrc/device-tree_v0_00_x/xilinx.dts

all: $(OUT_DIR) $(PS_CORE) $(FPGA_BIT) $(FSBL_ELF)

clean :
	rm -rf $(OUT_DIR)

$(OUT_DIR) :
	mkdir $(OUT_DIR)

$(PS_CORE) :
	cd $(OUT_DIR) && \
	    $(VIVADO) && vivado -mode batch -source ../buid_ps.tcl

$(FPGA_BIT):
	cd $(OUT_DIR) && \
	    $(VIVADO) && vivado -mode batch -source ../buid_top.tcl

$(FSBL_ELF):


