# Top level make file for building PandA socket server and associated device
# drivers for interfacing to the FPGA resources.

TOP = $(CURDIR)

BUILD_DIR = $(CURDIR)/build

include CONFIG

DRIVER_BUILD_DIR = $(BUILD_DIR)/driver
SERVER_BUILD_DIR = $(BUILD_DIR)/server

DRIVER_FILES := $(wildcard driver/*)
SERVER_FILES := $(wildcard server/*)

PATH := $(BINUTILS_DIR):$(PATH)

default: driver server


$(DRIVER_BUILD_DIR) $(SERVER_BUILD_DIR):
	mkdir -p $@


PANDA_KO = $(DRIVER_BUILD_DIR)/panda.ko

# Building kernel modules out of tree is a headache.  The best workaround is to
# link all the source files into the build directory.
DRIVER_BUILD_FILES := $(DRIVER_FILES:driver/%=$(DRIVER_BUILD_DIR)/%)
$(DRIVER_BUILD_FILES): $(DRIVER_BUILD_DIR)/%: driver/%
	ln -s $$(readlink -e $<) $@


$(PANDA_KO): $(DRIVER_BUILD_DIR) $(DRIVER_BUILD_FILES)
	make -C $(KERNEL_DIR) M=$< modules \
            ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE)
	touch $@


driver: $(PANDA_KO)

server: $(SERVER_BUILD_DIR) $(SERVER_FILES)

clean:
	rm -rf $(BUILD_DIR)

.PHONY: default server driver clean


deploy: $(PANDA_KO)
	scp $^ root@172.23.252.202:/opt

.PHONY: deploy
