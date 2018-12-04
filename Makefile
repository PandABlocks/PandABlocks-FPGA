# Top level make file for building PandA FPGA images

TOP := $(CURDIR)


# The following symbols MUST be defined in the CONFIG file before being used.
PANDA_ROOTFS = $(error Define PANDA_ROOTFS in CONFIG file)
ISE = $(error Define ISE in CONFIG file)
VIVADO = $(error Define VIVADO in CONFIG file)
APP_NAME = $(error Define APP_NAME in CONFIG file)

# Build defaults that can be overwritten by the CONFIG file if required
PYTHON = python2
SPHINX_BUILD = sphinx-build
MAKE_ZPKG = $(PANDA_ROOTFS)/make-zpkg

BUILD_DIR = $(TOP)/build
DEFAULT_TARGETS = zpkg


# The CONFIG file is required.  If not present, create by copying CONFIG.example
# and editing as appropriate.
include CONFIG


# Now we've loaded the CONFIG compute all the appropriate destinations
TEST_DIR = $(BUILD_DIR)/tests
IP_DIR = $(BUILD_DIR)/ip_repo
APP_BUILD_DIR = $(BUILD_DIR)/apps/$(APP_NAME)
AUTOGEN_BUILD_DIR = $(APP_BUILD_DIR)/autogen
FPGA_BUILD_DIR = $(APP_BUILD_DIR)/FPGA
SLOW_FPGA_BUILD_DIR = $(APP_BUILD_DIR)/SlowFPGA

# The TARGET defines the class of application and is extracted from the first
# part of the APP_NAME.
TARGET = $(firstword $(subst -, ,$(APP_NAME)))
TARGET_DIR = $(TOP)/targets/$(TARGET)


default: $(DEFAULT_TARGETS)
.PHONY: default


# ------------------------------------------------------------------------------
# App source autogeneration

APP_FILE = $(TOP)/apps/$(APP_NAME).app.ini

APP_DEPENDS += common/python/generate_app.py
APP_DEPENDS += $(wildcard common/templates/*)

# Make the built app from the ini file
$(AUTOGEN_BUILD_DIR): $(APP_FILE) $(APP_DEPENDS)
	rm -rf $@
	$(PYTHON) -m common.python.generate_app $@ $<

apps: $(AUTOGEN_BUILD_DIR)
.PHONY: apps


# ------------------------------------------------------------------------------
# Version symbols for FPGA bitstream generation etc

# Something like 0.1-1-g5539563-dirty
export GIT_VERSION := $(shell git describe --abbrev=7 --dirty --always --tags)
# Split and append .0 to get 0.1.0, then turn into hex to get 00000100
export VERSION := $(shell ./common/python/parse_git_version.py "$(GIT_VERSION)")
# 8 if dirty, 0 if clean
DIRTY_PRE = $(shell \
    python -c "print 8 if '$(GIT_VERSION)'.endswith('dirty') else 0")
# Something like 85539563
export SHA := $(DIRTY_PRE)$(shell git rev-parse --short HEAD)


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

# MODULE for every modules/MODULE/BLOCK.timing.ini
MODULES = $(sort $(dir $(patsubst modules/%,%,$(TIMINGS))))

# build/hdl_timing/MODULE for every MODULE
TIMING_BUILD_DIRS = $(patsubst %/,$(BUILD_DIR)/hdl_timing/%,$(MODULES))

# Make the built app from the ini file
$(BUILD_DIR)/hdl_timing/%: modules/%/*.timing.ini
	rm -rf $@_tmp $@
	$(PYTHON) -m common.python.generate_hdl_timing $@_tmp $^
	mv $@_tmp $@

# Make the hdl_timing folders and run all tests, or specific module by setting
# the MODULE argument
hdl_test: $(TIMING_BUILD_DIRS)
	rm -rf $(TEST_DIR)/regression_tests
	rm -rf $(TEST_DIR)/*.jou
	rm -rf $(TEST_DIR)/*.log
	mkdir -p $(TEST_DIR)
	cd $(TEST_DIR) && source $(VIVADO) && vivado -mode batch -notrace \
	 -source ../../tests/hdl/regression_tests.tcl -tclargs $(MODULE)

# Make the hdl_timing folders and run a single test, set TEST argument
single_hdl_test: $(TIMING_BUILD_DIRS)
	rm -rf $(TEST_DIR)/single_test
	rm -rf $(TEST_DIR)/*.jou
	rm -rf $(TEST_DIR)/*.log
	mkdir -p $(TEST_DIR)
	cd $(TEST_DIR) && source $(VIVADO) && vivado -mode batch -notrace \
	 -source ../../tests/hdl/single_test.tcl -tclargs $(TEST)

# Make the hdl_timing folders without running tests
hdl_timing: $(TIMING_BUILD_DIRS)
.PHONY: hdl_timing


# ------------------------------------------------------------------------------
# FPGA build

FPGA_FILE = $(FPGA_BUILD_DIR)/panda_top.bit
SLOW_FPGA_FILE = $(SLOW_FPGA_BUILD_DIR)/slow_top.bin

FPGA_DEPENDS =

SLOW_FPGA_DEPENDS =
SLOW_FPGA_DEPENDS += tools/virtexHex2Bin

tools/virtexHex2Bin: tools/virtexHex2Bin.c
	gcc -o $@ $<


$(FPGA_FILE): $(AUTOGEN_BUILD_DIR) $(FPGA_DEPENDS)
	echo building FPGA
	mkdir -p $(dir $@)
ifdef SKIP_FPGA_BUILD
	touch $@
else
	$(MAKE) -C $(dir $@) -f $(TARGET_DIR)/Makefile VIVADO=$(VIVADO) \
            TOP=$(TOP) TARGET_DIR=$(TARGET_DIR) BUILD_DIR=$(dir $@) \
            IP_DIR=$(IP_DIR)
endif

$(SLOW_FPGA_FILE): $(AUTOGEN_BUILD_DIR) $(SLOW_FPGA_DEPENDS)
	echo building SlowFPGA
	mkdir -p $(dir $@)
ifdef SKIP_FPGA_BUILD
	touch $@
else
	source $(ISE)  &&  \
        $(MAKE) -C $(dir $@) -f $(TARGET_DIR)/SlowFPGA/Makefile \
            TOP=$(TOP) SRC_DIR=$(TARGET_DIR)/SlowFPGA BOARD=$(BOARD) mcs \
            BUILD_DIR=$(dir $@)
endif

slow-fpga: $(SLOW_FPGA_BUILD_DIR)
.PHONY: slow-fpga

carrier-fpga: $(FPGA_BUILD_DIR)
.PHONY: carrier-fpga


# ------------------------------------------------------------------------------
# Build installation package

ZPKG_LIST = etc/panda-fpga.list
ZPKG_VERSION = $(APP_NAME)-$(GIT_VERSION)
ZPKG_FILE = $(BUILD_DIR)/panda-fpga@$(ZPKG_VERSION).zpg

ZPKG_DEPENDS += $(FPGA_FILE)
ZPKG_DEPENDS += $(SLOW_FPGA_FILE)

$(ZPKG_FILE): $(ZPKG_LIST) $(ZPKG_DEPENDS)
	$(MAKE_ZPKG) -t $(TOP) -b $(APP_BUILD_DIR) -d $(BUILD_DIR) \
            $< $(ZPKG_VERSION)

zpkg: $(ZPKG_FILE)
.PHONY: zpkg


# ------------------------------------------------------------------------------
# Clean

# Removes the built stuff, but not the built FPGA IP
clean:
	rm -rf $(BUILD_DIR)/apps
.PHONY: clean

clean-all:
	rm -rf $(BUILD_DIR) $(DOCS_BUILD_DIR) *.zpg
	find -name '*.pyc' -delete
.PHONY: clean-all

# Remove the Xilinx IP
ip_clean:
	rm -rf $(IP_DIR)
.PHONY: ip_clean
