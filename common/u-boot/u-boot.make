# Sub-make file for building u-boot.

# Some definitions of source file checksums to try and ensure repeatability of
# builds.  These releases are downloaded (as .tar.gz files) from:
#      https://github.com/Xilinx/u-boot-xlnx
#      https://github.com/Xilinx/linux-xlnx
# Note: if these files have been downloaded through the releases directory then
# they need to be renamed with the appropriate {u-boot,linux}-xlnx- prefix so
# that the file name and contents match.
MD5_SUM_u-boot-xlnx-xilinx-v2015.1 = b6d212208b7694f748727883eebaa74e
#MD5_SUM_linux-xlnx-xilinx-v2015.1  = 930d126df2113221e63c4ec4ce356f2c

include $(TGT_DIR)/u-boot_incl.make


U_BOOT_TAG = xilinx-v2015.1

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
#	 # Path to tools will vary depending on version of Vivado/Vitis
#	 # For 2017.3 onwards:
#	export PATH := $(SDK_ROOT)/gnu/aarch32/lin/gcc-arm-linux-gnueabi/bin:$(PATH)
#    # From Vivado 2020 onwards we can use the common defconfig
#    #UBOOT_CONFIG = xilinx_zynq_virt_defconfig
#    # For ealier Vivado we can specify zc70x as a generic config, as we are only using it to build mkimage
#    UBOOT_CONFIG = zynq_zc70x_config
#else ifeq($(PLATFORM,zynqmp)
#    ARCH=aarch64
#    CROSS_COMPILE=aarch64-linux-gnu-
#	 # Path to tools will vary depending on version of Vivado/Vitis
#	 # For 2017.3 onwards:
#	export PATH := $(SDK_ROOT)/gnu/aarch64/lin/aarch64-linux/bin:$(PATH)
#    # From Vivado 2020 onwards we can use the common defconfig
#    #UBOOT_CONFIG = xilinx_zynqmp_virt_defconfig
#    # For earlier Vivado verions, we can try zcu102 as an initial guess for the relevant config.
#    UBOOT_CONFIG = xilinx_zynqmp_zcu102_rev1_0_defconfig
#else
#    $$(error Unknown PLATFORM specified. Must be 'zynq' or 'zynqmp')

CROSS_COMPILE = arm-xilinx-linux-gnueabi-
ARCH = arm

export PATH := $(SDK_ROOT)/gnu/arm/lin/bin:$(PATH)


# ------------------------------------------------------------------------------
# Helper code lifted from rootfs and other miscellaneous functions

# Use the rootfs extraction tool to decompress our source trees.
EXTRACT_FILE = $(ROOTFS_TOP)/scripts/extract-tar $(SRC_ROOT) $1 $2 $(TAR_FILES)

# ------------------------------------------------------------------------------
# Building u-boot
#

U_BOOT_NAME = u-boot-xlnx-$(U_BOOT_TAG)
U_BOOT_SRC = $(SRC_ROOT)/$(U_BOOT_NAME)

MAKE_U_BOOT = $(MAKE) -C $(U_BOOT_SRC) \
  ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) KBUILD_OUTPUT=$(U_BOOT_BUILD)

u-boot: $(U_BOOT_SRC) $(DEVICE_TREE_DTB)
	mkdir -p $(U_BOOT_BUILD)
	$(MAKE_U_BOOT) $(UBOOT_CONFIG) 
	$(MAKE_U_BOOT) EXT_DTB=$(DEVICE_TREE_DTB)

$(U_BOOT_SRC):
	mkdir -p $(SRC_ROOT)
	$(call EXTRACT_FILE,$(U_BOOT_NAME).tar.gz,$(MD5_SUM_$(U_BOOT_NAME)))
	patch -p1 -d $(U_BOOT_SRC) < $(TOP)/common/u-boot/u-boot.patch
	patch -p1 -d $(U_BOOT_SRC) < $(TOP)/common/u-boot/u-boot_rsa.patch
	ln -s $(TOP)/common/u-boot/PandA_defconfig $(U_BOOT_SRC)/configs
	ln -s $(TOP)/common/u-boot/PandA.h $(U_BOOT_SRC)/include/configs/PandA.h
	chmod -R a-w $(U_BOOT_SRC)

u-boot-src: $(U_BOOT_SRC)

.PHONY: u-boot u-boot-src



