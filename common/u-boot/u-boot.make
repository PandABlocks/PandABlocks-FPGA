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

U_BOOT_TAG = xilinx-v2015.1

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
	. $(VIVADO) && $(MAKE_U_BOOT) $(UBOOT_CONFIG) 
	. $(VIVADO) && $(MAKE_U_BOOT) EXT_DTB=$(DEVICE_TREE_DTB)

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

