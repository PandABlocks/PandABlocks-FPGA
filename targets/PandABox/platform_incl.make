# Define target platform for cross-compiler
# Either 'zynq' for Zynq-7000 (Default) or 'zynqmp' for Zynq UltraScale+ MPSoC
PLATFORM = zynq
# UBOOT_DTS must match the name in uboot/kernel sources /arch/arm/dts
UBOOT_DTS = "zynq-picozed"
# If appropriate DTS file is not included in the kernel sources, \
# we can specify to use the built DTB for the target instead. \
# Note this does NOT work for ZedBoard but does for PandABox.
# UBOOT_USE_EXT_DTB = 

