#!/bin/bash
# Generates and populates PandABlocks-fpga CONFIG file.

cat >> PandABlocks-fpga/CONFIG << 'EOL'
# Default build location.  Default is to build in build subdirectory.
BUILD_DIR = /build/PandA-FPGA

# Development Tool Version
export VIVADO_VER = 2020.2

# Definitions needed for FPGA build
export VIVADO = /scratch/Xilinx/Vivado/\$(VIVADO_VER)/settings64.sh

# Location of rootfs builder.  This needs to be at least version 1.13 and can be
# downloaded from https://github.com/araneidae/rootfs
export ROOTFS_TOP = /rootfs

# Where to find source files
export TAR_FILES = /tar-files

# Path to root filesystem
PANDA_ROOTFS = /repos/PandABlocks-rootfs
MAKE_ZPKG = $(PANDA_ROOTFS)/make-zpkg

# Python interpreter for running scripts
PYTHON = python3

# Sphinx build for documentation.
SPHINX_BUILD = sphinx-build

# List of default targets to build when running make
DEFAULT_TARGETS = zpkg

# FPGA Application Name
APP_NAME = PandABox-no-fmc

EOL
