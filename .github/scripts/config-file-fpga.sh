#!/bin/bash
# Generates and populates PandABlocks-fpga CONFIG file.

cat >> PandABlocks-fpga/CONFIG << 'EOL'
# Default build location.  Default is to build in build subdirectory.
BUILD_DIR = $(GITHUB_WORKSPACE)/build

# Development Tool Version
export VIVADO_VER = 2020.2

# Definitions needed for FPGA build
export VIVADO = /scratch/Xilinx/Vivado/\$(VIVADO_VER)/settings64.sh
# export ISE = /dls_sw/FPGA/Xilinx/14.7/ISE_DS/settings64.sh
# export LM_LICENSE_FILE = 2100@diamcslicserv01.dc.diamond.ac.uk

# Location of rootfs builder.  This needs to be at least version 1.13 and can be
# downloaded from https://github.com/araneidae/rootfs
export ROOTFS_TOP = $(GITHUB_WORKSPACE)/rootfs

# Where to find source files
export TAR_FILES = $(GITHUB_WORKSPACE)/tar-files

# Path to root filesystem
PANDA_ROOTFS = $(GITHUB_WORKSPACE)/PandABlocks-rootfs
MAKE_ZPKG = $(PANDA_ROOTFS)/make-zpkg

# Python interpreter for running scripts
PYTHON = python3

# Sphinx build for documentation.
SPHINX_BUILD = sphinx-build

# List of default targets to build when running make
DEFAULT_TARGETS = zpkg

# FPGA Application Name
EOL
