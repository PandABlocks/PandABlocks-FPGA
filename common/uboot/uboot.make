# Top level make file for building u-boot, kernel, rootfs.

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

CROSS_COMPILE = arm-xilinx-linux-gnueabi-
ARCH = arm

SRC_ROOT = $(PANDA_ROOT)/src

# ------------------------------------------------------------------------------
# Building u-boot
#

U_BOOT_NAME = u-boot-xlnx-$(U_BOOT_TAG)
U_BOOT_SRC = $(SRC_ROOT)/$(U_BOOT_NAME)
U_BOOT_ELF = $(U_BOOT_BUILD)/u-boot.elf

MAKE_U_BOOT = $(MAKE) -C $(U_BOOT_SRC) \
  ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) KBUILD_OUTPUT=$(U_BOOT_BUILD)

$(U_BOOT_SRC):
	mkdir -p $(SRC_ROOT)
	$(call EXTRACT_FILE,$(U_BOOT_NAME).tar.gz,$(MD5_SUM_$(U_BOOT_NAME)))
	patch -p1 -d $(U_BOOT_SRC) < u-boot/u-boot.patch
	ln -s $(PWD)/u-boot/PandA_defconfig $(U_BOOT_SRC)/configs
	ln -s $(PWD)/u-boot/PandA.h $(U_BOOT_SRC)/include/configs
	chmod -R a-w $(U_BOOT_SRC)

$(U_BOOT_ELF) $(U_BOOT_TOOLS)/mkimage: $(U_BOOT_SRC) $(DEVICE_TREE_DTB)
	mkdir -p $(U_BOOT_BUILD)
	$(MAKE_U_BOOT) PandA_config
	$(MAKE_U_BOOT) EXT_DTB=$(DEVICE_TREE_DTB)
	ln -sf u-boot $(U_BOOT_ELF)


#### ???
u-boot: $(U_BOOT_ELF)
u-boot-src: $(U_BOOT_SRC)

.PHONY: u-boot u-boot-src



