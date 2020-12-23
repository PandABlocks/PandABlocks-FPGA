# Top level make file for building PandA FPGA images

TOP := $(CURDIR)

# Need bash for the source command in Xilinx settings64.sh
SHELL = /bin/bash

# The following symbols MUST be defined in the CONFIG file before being used.
PANDA_ROOTFS = $(error Define PANDA_ROOTFS in CONFIG file)
ISE = $(error Define ISE in CONFIG file)
VIVADO = $(error Define VIVADO in CONFIG file)
APP_NAME = $(error Define APP_NAME in CONFIG file)

# Build defaults that can be overwritten by the CONFIG file if required
PYTHON = python
SPHINX_BUILD = sphinx-build
MAKE_ZPKG = $(PANDA_ROOTFS)/make-zpkg
MAKE_GITHUB_RELEASE = $(PANDA_ROOTFS)/make-github-release.py

BUILD_DIR = $(TOP)/build
VIVADO_VER = 2015.2
DEFAULT_TARGETS = zpkg


# The CONFIG file is required.  If not present, create by copying CONFIG.example
# and editing as appropriate.
include CONFIG


# Now we've loaded the CONFIG compute all the appropriate destinations
TGT_BUILD_DIR = $(BUILD_DIR)/targets/$(TARGET)
TEST_DIR = $(TGT_BUILD_DIR)/tests
#IP_DIR = $(TGT_BUILD_DIR)/ip_repo
APP_BUILD_DIR = $(BUILD_DIR)/apps/$(APP_NAME)
AUTOGEN_BUILD_DIR = $(APP_BUILD_DIR)/autogen
FPGA_BUILD_DIR = $(APP_BUILD_DIR)/FPGA

# The TARGET defines the class of application and is extracted from the first
# part of the APP_NAME.
TARGET = $(firstword $(subst -, ,$(APP_NAME)))
TARGET_DIR = $(TOP)/targets/$(TARGET)

# Location of Vivado project files and default run-modes
# Need different MODE variables for TOP and PS/IP as PS/IP are prerequisites of TOP 
PS_PROJ = $(TGT_BUILD_DIR)/panda_ps/panda_ps.xpr
IP_PROJ = $(TGT_BUILD_DIR)/ip_repo/managed_ip_project/managed_ip_project.xpr
TOP_PROJ = $(FPGA_BUILD_DIR)/panda_top/carrier_fpga_top.xpr
TOP_MODE ?= batch
DEP_MODE ?= batch

# Store the git hash in top-level build directory 
PREV_VER = $(BUILD_DIR)/VERSION

default: $(DEFAULT_TARGETS)
all: python_tests python_timing hdl_test default boot
.PHONY: default all


# If ALL_APPS not specified in CONFIG, pick up all valid entries in the apps dir
ifndef ALL_APPS
ALL_APPS := $(wildcard apps/*.app.ini)
# Exclude udpontrig apps as they can't currently be built with our license
ALL_APPS := $(filter-out $(wildcard apps/*udpontrig*),$(ALL_APPS))
ALL_APPS := $(filter-out $(wildcard apps/*eventr*),$(ALL_APPS))
ALL_APPS := $(notdir $(ALL_APPS))
ALL_APPS := $(ALL_APPS:.app.ini=)
endif


# Helper for MAKE_ALL_APPS below.  This separate definition is needed so that
# each generate makefile call is a separate command.
define _MAKE_ONE_APP
$(MAKE) APP_NAME=$(1) $(2)

endef

# Helper function for building all apps: invoke
#
#  $(call MAKE_ALL_APPS, target)
#
# to build target for all applications in the target directory
MAKE_ALL_APPS = $(foreach app,$(ALL_APPS), $(call _MAKE_ONE_APP,$(app),$(1)))


# ------------------------------------------------------------------------------
# App source autogeneration

APP_FILE = $(TOP)/apps/$(APP_NAME).app.ini

APP_DEPENDS += $(wildcard common/python/*.py)
APP_DEPENDS += $(wildcard common/templates/*)
APP_DEPENDS += $(wildcard includes/*)
APP_DEPENDS += $(wildcard targets/*/*.ini)
APP_DEPENDS += $(wildcard modules/*/const/*.xdc)

# Make the built app from the ini file
$(AUTOGEN_BUILD_DIR): $(APP_FILE) $(APP_DEPENDS)
	rm -rf $@
	$(PYTHON) -m common.python.generate_app $@ $<

autogen: $(AUTOGEN_BUILD_DIR)
.PHONY: autogen

all_autogen:
	$(call MAKE_ALL_APPS,autogen)
.PHONY: all_autogen


# ------------------------------------------------------------------------------
# Version symbols for FPGA bitstream generation etc

# Something like 0.1-1-g5539563-dirty
export GIT_VERSION := $(shell git describe --abbrev=7 --dirty --always --tags)
# Split and append .0 to get 0.1.0, then turn into hex to get 00000100
export VERSION := $(shell ./common/python/parse_git_version.py "$(GIT_VERSION)")
# 8 if dirty, 0 if clean
DIRTY_PRE = $(shell \
    python -c "print(8 if '$(GIT_VERSION)'.endswith('dirty') else 0)")
# Something like 85539563
export SHA := $(DIRTY_PRE)$(shell git rev-parse --short=7 HEAD)

# Trigger rebuild of FPGA targets based on change in the git hash
# If the previous hash value does not exist, or disagrees with the present
# value, or contains the 'dirty' string then the FPGA build will be considered
# out-of-date.

.PHONY: PREV_VERSION
PREV_VERSION :
ifeq ($(wildcard $(PREV_VER)), ) 
	echo $(SHA) > $(PREV_VER)    
else
	if [[ $(SHA) != `cat $(PREV_VER)` ]] || [[ $(SHA) == 8* ]]; \
	then echo $(SHA) > $(PREV_VER); \
	fi
endif

# ------------------------------------------------------------------------------
# Documentation

# Generated rst sources from modules are put here, unfortunately it has to be in
# the docs dir otherwise matplotlib plot_directive screws up
DOCS_BUILD_DIR = $(TOP)/docs/build

# The html docs are built into this dir
DOCS_HTML_DIR = $(BUILD_DIR)/html
ALL_RST_FILES = $(shell find docs modules -name '*.rst')
BUILD_RST_FILES = $(wildcard docs/build/*.rst)
SRC_RST_FILES = $(filter-out $(BUILD_RST_FILES),$(ALL_RST_FILES))

$(DOCS_HTML_DIR): docs/conf.py $(SRC_RST_FILES)
	$(SPHINX_BUILD) -b html docs $@

docs: $(DOCS_HTML_DIR)
.PHONY: docs


# ------------------------------------------------------------------------------
# Tests

# Test just the python framework
python_tests:
	$(PYTHON) -m unittest discover -v tests.python
.PHONY: python_tests

# Test just the timing for simulations
python_timing:
	$(PYTHON) -m unittest -v tests.test_python_sim_timing
.PHONY: python_timing


# ------------------------------------------------------------------------------
# Timing test benches using vivado to run FPGA simulations

# every modules/MODULE/BLOCK.timing.ini
TIMINGS = $(wildcard modules/*/*.timing.ini)

# MODULE for every modules/MODULE_DIR/BLOCK.timing.ini
MODULE_DIRS = $(sort $(dir $(patsubst modules/%,%,$(TIMINGS))))

# Remove trailing backslash from module directory names
MODULES = $(patsubst %/,%,$(MODULE_DIRS))

# build/hdl_timing/MODULE for every MODULES
TIMING_BUILD_DIRS = $(patsubst %,$(BUILD_DIR)/hdl_timing/%,$(MODULES))

# Make the built app from the ini file
$(BUILD_DIR)/hdl_timing/%: modules/%/*.timing.ini
	rm -rf $@_tmp $@
	$(PYTHON) -m common.python.generate_hdl_timing $@_tmp $^
	mv $@_tmp $@

# Make the hdl_timing folders and run all tests, or specific modules by setting
# the MODULES argument
hdl_test: $(TIMING_BUILD_DIRS) $(BUILD_DIR)/hdl_timing/pcap carrier_ip
	rm -rf $(TEST_DIR)/regression_tests
	rm -rf $(TEST_DIR)/*.jou
	rm -rf $(TEST_DIR)/*.log
	mkdir -p $(TEST_DIR)
	cd $(TEST_DIR) && . $(VIVADO) && vivado -mode batch -notrace \
	 -source $(TOP)/tests/hdl/regression_tests.tcl \
	-tclargs $(TOP) $(TARGET_DIR) $(TGT_BUILD_DIR) $(BUILD_DIR) $(MODULES)

# Make the hdl_timing folders and run a single test, set TEST argument
# E.g. make TEST="clock 1" single_hdl_test
single_hdl_test: $(TIMING_BUILD_DIRS) $(BUILD_DIR)/hdl_timing/pcap carrier_ip
	rm -rf $(TEST_DIR)/single_test
	rm -rf $(TEST_DIR)/*.jou
	rm -rf $(TEST_DIR)/*.log
	mkdir -p $(TEST_DIR)
	cd $(TEST_DIR) && . $(VIVADO) && vivado -mode batch -notrace \
	 -source $(TOP)/tests/hdl/single_test.tcl -tclargs \
	-tclargs $(TOP) $(TARGET_DIR) $(TGT_BUILD_DIR) $(BUILD_DIR) $(TEST)

# Make the hdl_timing folders without running tests
hdl_timing: $(TIMING_BUILD_DIRS)
.PHONY: hdl_timing


# ------------------------------------------------------------------------------
# FPGA build

# The following phony targets are passed straight to the FPGA sub-make programme
FPGA_TARGETS = fpga-all fpga-bits carrier_fpga slow_fpga slow_load carrier_ip ps_core \
               fsbl devicetree boot u-boot dts sw_clean

$(FPGA_TARGETS): $(TOP)/common/fpga.make $(AUTOGEN_BUILD_DIR) | PREV_VERSION
	mkdir -p $(FPGA_BUILD_DIR)
	mkdir -p $(TGT_BUILD_DIR)
ifdef SKIP_FPGA_BUILD
	@echo Skipping FPGA build
else
	@echo building FPGA
	$(MAKE) -C $(FPGA_BUILD_DIR) -f $< VIVADO_VER=$(VIVADO_VER) \
        TOP=$(TOP) TARGET_DIR=$(TARGET_DIR) APP_BUILD_DIR=$(APP_BUILD_DIR) \
        TGT_BUILD_DIR=$(TGT_BUILD_DIR) TOP_MODE=$(TOP_MODE) DEP_MODE=$(DEP_MODE) \
		PREV_VER=$(PREV_VER) $@
endif

.PHONY: $(FPGA_TARGETS)

# Targets to launch and edit vivado projects in interactive mode
# Targets : edit_ps_bd ; edit_ips ; carrier-fpga_gui

edit_ps_bd: DEP_MODE=gui 
ifeq ($(wildcard $(PS_PROJ)), )
  edit_ps_bd: ps_core
else
  edit_ps_bd : 
	cd $(TGT_BUILD_DIR)/panda_ps; \
	source $(VIVADO) && vivado -mode $(DEP_MODE) $(PS_PROJ)
endif

edit_ips: DEP_MODE=gui
ifeq ($(wildcard $(IP_PROJ)), )
  edit_ips: carrier_ip
else
  edit_ips:
	cd $(TGT_BUILD_DIR)/ip_repo; \
	source $(VIVADO) && vivado -mode $(DEP_MODE) $(IP_PROJ)
endif

carrier-fpga_gui: TOP_MODE=gui 
ifeq ($(wildcard $(TOP_PROJ)), )
  carrier-fpga_gui: carrier_fpga
else
  carrier-fpga_gui : 
	cd $(FPGA_BUILD_DIR); \
	source $(VIVADO) && vivado -mode $(TOP_MODE) $(TOP_PROJ)
endif

.PHONY: edit_ps_bd edit_ips carrier-fpga_gui


# ------------------------------------------------------------------------------
# Build installation package

ZPKG_LIST = targets/$(TARGET)/etc/panda-fpga.list
ZPKG_VERSION = $(APP_NAME)-$(GIT_VERSION)
ZPKG_FILE = $(BUILD_DIR)/panda-fpga@$(ZPKG_VERSION).zpg

ZPKG_DEPENDS += fpga-bits
ZPKG_DEPENDS += $(APP_BUILD_DIR)/ipmi.ini
ZPKG_DEPENDS += $(APP_BUILD_DIR)/extensions
ZPKG_DEPENDS += $(DOCS_HTML_DIR)

$(APP_BUILD_DIR)/ipmi.ini: $(APP_FILE)
	$(PYTHON) -m common.python.make_ipmi_ini $(TOP) $< $@

$(APP_BUILD_DIR)/extensions: $(APP_FILE)
	rm -rf $@
	mkdir -p $@
	$(PYTHON) -m common.python.make_extensions $(TOP) $< $(TARGET) $@

# Unconditionally rebuild the extensions and ipmi.ini files.  This is cheap and
# the result is more predictable
.PHONY: $(APP_BUILD_DIR)/ipmi.ini $(APP_BUILD_DIR)/extensions


$(ZPKG_FILE): $(ZPKG_LIST) $(ZPKG_DEPENDS)
	$(MAKE_ZPKG) -t $(TOP) -b $(APP_BUILD_DIR) -d $(BUILD_DIR) \
            $< $(ZPKG_VERSION)

zpkg: $(ZPKG_FILE)
.PHONY: zpkg

all-zpkg:
	$(call MAKE_ALL_APPS, zpkg)
.PHONY: all-zpkg

#-------------------------------------------------------------------------------

# Push a github release
github-release: $(ZPKG)
	$(MAKE_GITHUB_RELEASE) PandABlocks-FPGA $(GIT_VERSION) \
	    $(BUILD_DIR)/*.zpg

.PHONY: github-release

# ------------------------------------------------------------------------------
# Clean

# Removes the built stuff, but not the built FPGA IP
clean:
	rm -rf $(BUILD_DIR)/apps
.PHONY: clean

clean-all:
	-chmod -R +w $(BUILD_DIR)/src
	rm -rf $(BUILD_DIR) $(DOCS_BUILD_DIR) *.zpg
	find -name '*.pyc' -delete
.PHONY: clean-all

# Remove the Xilinx IP
ip_clean:
	rm -rf $(TGT_BUILD_DIR)
.PHONY: ip_clean
