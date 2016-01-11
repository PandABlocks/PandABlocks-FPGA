# Top level make file for building PandA socket server and associated device
# drivers for interfacing to the FPGA resources.

TOP := $(CURDIR)

# Build defaults that can be overwritten by the CONFIG file if present

BUILD_DIR = $(TOP)/build
PYTHON = python2
ARCH = arm
CROSS_COMPILE = arm-xilinx-linux-gnueabi-
BINUTILS_DIR = /dls_sw/FPGA/Xilinx/SDK/2015.1/gnu/arm/lin/bin
KERNEL_DIR = $(error Define KERNEL_DIR before building driver)
DEFAULT_TARGETS = driver server sim_server docs
SIM_HARDWARE = sim_zebra2

-include CONFIG


CC = $(CROSS_COMPILE)gcc

DRIVER_BUILD_DIR = $(BUILD_DIR)/driver
SERVER_BUILD_DIR = $(BUILD_DIR)/server
SIM_SERVER_BUILD_DIR = $(BUILD_DIR)/sim_server
DOCS_BUILD_DIR = $(BUILD_DIR)/html

DRIVER_FILES := $(wildcard driver/*)
SERVER_FILES := $(wildcard server/*)

ifdef BINUTILS_DIR
PATH := $(BINUTILS_DIR):$(PATH)
endif

default: $(DEFAULT_TARGETS)
.PHONY: default


$(BUILD_DIR)/%:
	mkdir -p $@


# ------------------------------------------------------------------------------
# Kernel driver building

PANDA_KO = $(DRIVER_BUILD_DIR)/panda.ko

# Building kernel modules out of tree is a headache.  The best workaround is to
# link all the source files into the build directory.
DRIVER_BUILD_FILES := $(DRIVER_FILES:driver/%=$(DRIVER_BUILD_DIR)/%)
$(DRIVER_BUILD_FILES): $(DRIVER_BUILD_DIR)/%: driver/%
	ln -s $$(readlink -e $<) $@


$(PANDA_KO): $(DRIVER_BUILD_DIR) $(DRIVER_BUILD_FILES)
	$(MAKE) -C $(KERNEL_DIR) M=$< modules \
            ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE)
	touch $@


driver: $(PANDA_KO)
.PHONY: driver


# ------------------------------------------------------------------------------
# Socket server

SERVER = $(SERVER_BUILD_DIR)/server
SIM_SERVER = $(SIM_SERVER_BUILD_DIR)/sim_server
SERVER_FILES := $(wildcard server/*)

$(SERVER): $(SERVER_BUILD_DIR) $(SERVER_FILES)
	$(MAKE) -C $< -f $(TOP)/server/Makefile \
            VPATH=$(TOP)/server TOP=$(TOP) CC=$(CC)

# Two differences with building sim_server: we use the native compiler, not the
# cross-compiler, and we only build the sim_server target.
$(SIM_SERVER): $(SIM_SERVER_BUILD_DIR) $(SERVER_FILES)
	$(MAKE) -C $< -f $(TOP)/server/Makefile \
            VPATH=$(TOP)/server TOP=$(TOP) sim_server

# Construction of simserver launch script.
SIMSERVER_SUBSTS += s:@@PYTHON@@:$(PYTHON):;
SIMSERVER_SUBSTS += s:@@BUILD_DIR@@:$(BUILD_DIR):;
SIMSERVER_SUBSTS += s:@@SIM_HARDWARE@@:$(SIM_HARDWARE):

simserver: simserver.in
	sed '$(SIMSERVER_SUBSTS)' $< >$@
	chmod +x $@

server: $(SERVER)
sim_server: $(SIM_SERVER) simserver

.PHONY: server sim_server


# ------------------------------------------------------------------------------
# Documentation

$(DOCS_BUILD_DIR)/index.html: $(wildcard docs/*.rst docs/*/*.rst docs/conf.py)
	sphinx-build -b html docs $(DOCS_BUILD_DIR)

docs: $(DOCS_BUILD_DIR)/index.html

.PHONY: docs


# ------------------------------------------------------------------------------

clean:
	rm -rf $(BUILD_DIR)
	rm -f simserver

.PHONY: clean


DEPLOY += $(PANDA_KO)
DEPLOY += $(SERVER)

deploy: $(DEPLOY)
	scp $^ root@172.23.252.202:/opt

.PHONY: deploy
