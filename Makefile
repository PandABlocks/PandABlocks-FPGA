# Top level make file for building PandA socket server and associated device
# drivers for interfacing to the FPGA resources.

TOP := $(CURDIR)

BUILD_DIR = $(TOP)/build

include CONFIG

CC = $(CROSS_COMPILE)gcc

DRIVER_BUILD_DIR = $(BUILD_DIR)/driver
SERVER_BUILD_DIR = $(BUILD_DIR)/server
SIM_SERVER_BUILD_DIR = $(BUILD_DIR)/sim_server

DRIVER_FILES := $(wildcard driver/*)
SERVER_FILES := $(wildcard server/*)

PATH := $(BINUTILS_DIR):$(PATH)

default: driver server sim_server
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
SIM_SERVER = $(SIM_SERVER_BUILD_DIR)/server
SERVER_FILES := $(wildcard server/*)

$(SERVER): $(SERVER_BUILD_DIR) $(SERVER_FILES)
	$(MAKE) -C $< -f $(TOP)/server/Makefile \
            VPATH=$(TOP)/server TOP=$(TOP) CC=$(CC)

$(SIM_SERVER): $(SIM_SERVER_BUILD_DIR) $(SERVER_FILES)
	$(MAKE) -C $< -f $(TOP)/server/Makefile \
            VPATH=$(TOP)/server TOP=$(TOP) SIMSERVER=T

server: $(SERVER)
sim_server: $(SIM_SERVER)

.PHONY: server sim_server


# ------------------------------------------------------------------------------

clean:
	rm -rf $(BUILD_DIR)
.PHONY: clean


DEPLOY += $(PANDA_KO)
DEPLOY += $(SERVER)

deploy: $(DEPLOY)
	scp $^ root@172.23.252.202:/opt

.PHONY: deploy
