# Top level make file for building PandA socket server and associated device
# drivers for interfacing to the FPGA resources.

TOP := $(CURDIR)

-include CONFIG

TARGET_DIR = $(TOP)/targets/$(TARGET)
DOCS_BUILD_DIR = $(BUILD_DIR)/$(TARGET)/html
FPGA_BUILD_DIR = $(BUILD_DIR)/$(TARGET)
SLOW_FPGA_BUILD_DIR = $(BUILD_DIR)/SlowFPGA
TEST_DIR = $(BUILD_DIR)/tests
TEST_SCRIPT_DIR = $(TOP)/tests/sim
ZPKG_SCRIPT = $(TOP)/make-zpkg

# Repeated from targets/PandABox/Makefile
IP_CORES = $(FPGA_BUILD_DIR)/ip_repo


default: $(DEFAULT_TARGETS)
.PHONY: default

# Something like 0.1-1-g5539563-dirty
export GIT_VERSION := $(shell git describe --abbrev=7 --dirty --always --tags)
# Split and append .0 to get 0.1.0, then turn into hex to get 00000100
export VERSION := $(shell ./python/parse_git_version.py "$(GIT_VERSION)")
# 8 if dirty, 0 if clean
DIRTY_PRE = $(shell python -c "print 8 if '$(GIT_VERSION)'.endswith('dirty') else 0")
# Something like 85539563
export SHA := $(DIRTY_PRE)$(shell git rev-parse --short HEAD)

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

# Extract FMC and SFP design names from config file
FMC_DESIGN = $(shell grep -o 'FMC_[^ ]*' $(APP_FILE) |tr A-Z a-z)
SFP_DESIGN = $(shell grep -o 'SFP_[^ ]*' $(APP_FILE) |tr A-Z a-z)

# Carrier FPGA targets
CARRIER_FPGA_TARGETS = carrier-fpga carrier-ip


run-tests: $(TEST_DIR) $(IP_CORES)
	rm -rf $(TEST_DIR)/regression_tests
	rm -rf $(TEST_DIR)/*.jou
	rm -rf $(TEST_DIR)/*.log
	cd common/python && ./fpga_vector_generator.py
	cd $(TEST_DIR) && source $(VIVADO) && vivado -mode batch -notrace -source $(TEST_SCRIPT_DIR)/regression_tests.tcl

config_d: $(FPGA_BUILD_DIR)
	rm -rf $(BUILD_DIR)/config_d
	cd common/python && ./config_generator.py -a $(APP_FILE) -o $(FPGA_BUILD_DIR)
	cd common/python && ./vhdl_generator.py -o $(FPGA_BUILD_DIR)

$(CARRIER_FPGA_TARGETS) $(IP_CORES): $(FPGA_BUILD_DIR) config_d
	$(MAKE) -C $< -f $(TARGET_DIR)/Makefile VIVADO=$(VIVADO) \
	    TOP=$(TOP) TARGET_DIR=$(TARGET_DIR) BUILD_DIR=$(FPGA_BUILD_DIR) \
		FMC_DESIGN=$(FMC_DESIGN) SFP_DESIGN=$(SFP_DESIGN) \
		$@

slow-fpga: $(SLOW_FPGA_BUILD_DIR) tools/virtexHex2Bin
	source $(ISE)  &&  $(MAKE) -C $< -f $(TOP)/SlowFPGA/Makefile \
            TOP=$(TOP) SRC_DIR=$(TOP)/SlowFPGA CARRIER_BUILD_DIR=$(FPGA_BUILD_DIR) BOARD=$(BOARD) mcs

tools/virtexHex2Bin : tools/virtexHex2Bin.c
	gcc -o $@ $<

.PHONY: carrier-fpga slow-fpga run-tests

# -------------------------------------------------------------------------
# Build installation package
# -------------------------------------------------------------------------

make-zpkg_update: 
	rm -f make-zpkg
	$(MAKE) $(ZPKG_SCRIPT)	

$(ZPKG_SCRIPT):
	wget $(MAKE_ZPKG_URL)
	chmod +x $(ZPKG_SCRIPT)

zpkg: etc/panda-fpga.list $(ZPKG_SCRIPT)
	rm -f $(BUILD_DIR)/*.zpg
	$(ZPKG_SCRIPT) -t $(BUILD_DIR) -b $(BUILD_DIR) -d $(BUILD_DIR) \
            $< $(APP_NAME)-$(GIT_VERSION)

.PHONY: zpkg make-zpkg_update

# -------------------------------------------------------------------------
# This needs to go more or less last to avoid conflict with other targets.
# -------------------------------------------------------------------------

$(BUILD_DIR)/%:
	mkdir -p $@

clean:
	rm -rf $(BUILD_DIR)
	find -name '*.pyc' -delete

.PHONY: clean

