# Top level make file for building PandA socket server and associated device
# drivers for interfacing to the FPGA resources.

TOP := $(CURDIR)

-include CONFIG
-include VERSION

export LM_LICENSE_FILE
export BUILD_DIR

TARGET_DIR = $(TOP)/targets/$(TARGET)
DOCS_BUILD_DIR = $(BUILD_DIR)/$(TARGET)/html
FPGA_BUILD_DIR = $(BUILD_DIR)/$(TARGET)
SLOW_FPGA_BUILD_DIR = $(BUILD_DIR)/SlowFPGA

default: $(DEFAULT_TARGETS)
.PHONY: default

export GIT_VERSION := $(shell git describe --abbrev=7 --dirty --always --tags)

# -------------------------------------------------------------------------
# Documentation
# -------------------------------------------------------------------------

export FPGA_BUILD_DIR
$(DOCS_BUILD_DIR)/index.html: $(wildcard docs/*.rst docs/*/*.rst docs/conf.py)
	$(SPHINX_BUILD) -b html docs $(DOCS_BUILD_DIR)

docs: $(DOCS_BUILD_DIR)/index.html

.PHONY: docs


# -------------------------------------------------------------------------
# FPGA builds
# -------------------------------------------------------------------------
APP_FILE = $(TOP)/apps/$(APP_NAME)
BUILD_DIR = $(TOP)/build

# Extract FMC and SFP design names from config file
FMC_DESIGN = $(shell grep -o 'FMC_[^ ]*' $(APP_FILE) |tr A-Z a-z)
SFP_DESIGN = $(shell grep -o 'SFP_[^ ]*' $(APP_FILE) |tr A-Z a-z)

# Carrier FPGA targets
CARRIER_FPGA_TARGETS = carrier-fpga carrier-ip

config_d: $(FPGA_BUILD_DIR)
	rm -rf $(BUILD_DIR)/config_d
	rm -rf $(BUILD_DIR)/CarrierFPGA/autogen
	cd common/python && ./config_generator.py -a $(APP_FILE) -o $(FPGA_BUILD_DIR)
	cd common/python && ./vhdl_generator.py -o $(FPGA_BUILD_DIR)

$(CARRIER_FPGA_TARGETS): $(FPGA_BUILD_DIR)
	$(MAKE) -C $< -f $(TARGET_DIR)/Makefile VIVADO=$(VIVADO) \
	    TOP=$(TOP) TARGET_DIR=$(TARGET_DIR) BUILD_DIR=$(FPGA_BUILD_DIR) \
		FMC_DESIGN=$(FMC_DESIGN) SFP_DESIGN=$(SFP_DESIGN) \
		$(MAKECMDGOALS)

slow-fpga: $(SLOW_FPGA_BUILD_DIR) tools/virtexHex2Bin
	source $(ISE)  &&  $(MAKE) -C $< -f $(TOP)/SlowFPGA/Makefile \
            TOP=$(TOP) SRC_DIR=$(TOP)/SlowFPGA BOARD=$(BOARD) mcs

tools/virtexHex2Bin : tools/virtexHex2Bin.c
	gcc -o $@ $<

.PHONY: carrier-fpga slow-fpga

# -------------------------------------------------------------------------
# Build installation package
# -------------------------------------------------------------------------

ZPKG_VERSION = $(BOARD)-$(FMC_DESIGN)_$(SFP_DESIGN)-$(FIRMWARE)

zpkg: etc/panda-fpga.list $(FIRMWARE_BUILD)
	rm -f $(BUILD_DIR)/*.zpg
	$(MAKE_ZPKG) -t $(BUILD_DIR) -b $(BUILD_DIR) -d $(BUILD_DIR) \
            $< $(ZPKG_VERSION)

.PHONY: zpkg

# -------------------------------------------------------------------------
# This needs to go more or less last to avoid conflict with other targets.
# -------------------------------------------------------------------------

$(BUILD_DIR)/%:
	mkdir -p $@

clean:
	rm -rf $(BUILD_DIR)
	find -name '*.pyc' -delete

.PHONY: clean

