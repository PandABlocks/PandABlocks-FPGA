# Top level make file for building PandA socket server and associated device
# drivers for interfacing to the FPGA resources.

TOP := $(CURDIR)

-include CONFIG
-include VERSION

export LM_LICENSE_FILE
export BUILD_DIR

TARGET = PandABox

DOCS_BUILD_DIR = $(BUILD_DIR)/html
SLOW_FPGA_BUILD_DIR = $(BUILD_DIR)/SlowFPGA
FPGA_BUILD_DIR = $(BUILD_DIR)/$(TARGET)
TARGET_DIR = $(TOP)/targets/$(TARGET)

default: $(DEFAULT_TARGETS)
.PHONY: default

export GIT_VERSION := $(shell git describe --abbrev=7 --dirty --always --tags)

# -------------------------------------------------------------------------
# Documentation
# -------------------------------------------------------------------------

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
#FMC_DESIGN = $(shell sed -n '/^FMC_/{s///;s/ .*//;p}' $(APP_FILE))
#SFP_DESIGN = $(shell sed -n '/^SFP_/{s///;s/ .*//;p}' $(APP_FILE))
FMC_DESIGN = fmc_loopback
SFP_DESIGN = sfp_loopback

INCR_DESIGN = false

carrier-fpga: $(FPGA_BUILD_DIR)
	rm -rf $(BUILD_DIR)/config_d
	rm -rf $(BUILD_DIR)/CarrierFPGA/autogen
	cd python && ./config_generator.py -a $(APP_FILE) -o $(FPGA_BUILD_DIR)
	cd python && ./vhdl_generator.py -o $(FPGA_BUILD_DIR)
	$(MAKE) -C $< -f $(TARGET_DIR)/Makefile VIVADO=$(VIVADO) \
	    TOP=$(TOP) TARGET_DIR=$(TARGET_DIR) BUILD_DIR=$(FPGA_BUILD_DIR) \
		FMC_DESIGN=$(FMC_DESIGN) SFP_DESIGN=$(SFP_DESIGN) \
			INCR_DESIGN=$(INCR_DESIGN)

slow-fpga: $(SLOW_FPGA_BUILD_DIR) tools/virtexHex2Bin
	source $(ISE)  &&  $(MAKE) -C $< -f $(TOP)/SlowFPGA/Makefile \
            TOP=$(TOP) SRC_DIR=$(TOP)/SlowFPGA BOARD=$(BOARD) mcs

tools/virtexHex2Bin : tools/virtexHex2Bin.c
	gcc -o $@ $<

.PHONY: carrier-fpga slow-fpga

# -------------------------------------------------------------------------
# Build installation package
# -------------------------------------------------------------------------

ZPKG_VERSION = $(BOARD)-FMC_$(FMC_DESIGN)_SFP_$(SFP_DESIGN)-$(FIRMWARE)

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

