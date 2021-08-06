#!/bin/bash
# Generates config files in PandABlocks-fpga and rootfs repositories and populates them with information.

PLATFORM=$1

# PandABlocks-rootfs:
# Create the CONFIG file
cd PandABlocks-rootfs
touch CONFIG

#Determine the toolchain to use
if [ "$PLATFORM" == "zynq" ]; 
    then
    TOOLCHAIN=gcc-arm-10.2-2020.11-x86_64-arm-none-linux-gnueabihf
elif [ "$PLATFORM" == "zynqmp" ]
    then
    TOOLCHAIN=gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu
fi

# Populate the CONFIG file
cat >> CONFIG <<EOL
# Location of rootfs builder
ROOTFS_TOP = \$(GITHUB_WORKSPACE)/rootfs

# Toolchain used to build the target
TOOLCHAIN_ROOT = \$(GITHUB_WORKSPACE)/$TOOLCHAIN

# Where to find source files
TAR_FILES = \$(GITHUB_WORKSPACE)/tar-files

# Target location for build
PANDA_ROOT = \$(GITHUB_WORKSPACE)/build

# Whether the platform is zynq or zyqnmp
PLATFORM = $PLATFORM
EOL

# rootfs:
# Create the CONFIG file
cd ../rootfs
touch CONFIG.local
# Populate the CONFIG file
cat >> CONFIG.local <<EOL
TARGET = minimal

# This is the location where source and build files will be placed.
ROOTFS_ROOT = \$(GITHUB_WORKSPACE)/build

# This is where all of the source tar files will be found.
TAR_DIRS = \$(GITHUB_WORKSPACE)/tar-files
EOL
