SLOW_FPGA_BUILD_DIR = $(TGT_BUILD_DIR)/SlowFPGA
SLOW_LOAD = $(TGT_BUILD_DIR)/slow_load


BITS_PREREQ += slow_fpga
BITS_PREREQ += slow_load

# Flags used in slow_load compilation
CC = $(CROSS_COMPILE)gcc
CFLAGS += -std=gnu99
CFLAGS += -O2
CFLAGS += -Werror
CFLAGS += -Wall
CFLAGS += -Wextra
CFLAGS += -Wundef
CFLAGS += -Wshadow
CFLAGS += -Wcast-align
CFLAGS += -Wwrite-strings
CFLAGS += -Wredundant-decls
CFLAGS += -Wmissing-prototypes
CFLAGS += -Wmissing-declarations
CFLAGS += -Wstrict-prototypes
CFLAGS += -Wcast-qual
CFLAGS += -Woverflow
CFLAGS += -Wconversion
CFLAGS += -Wsign-compare
CFLAGS += -Wstrict-overflow=5
CFLAGS += -Wno-switch-enum
CFLAGS += -Wno-variadic-macros
CFLAGS += -Wno-padded
CFLAGS += -Wno-format-nonliteral
CFLAGS += -Wno-vla
CFLAGS += -Wno-c++-compat
CFLAGS += -Wno-pointer-arith
CFLAGS += -Wno-unused-parameter
CFLAGS += -Wno-missing-field-initializers


# Build SlowFPGA Firmware target
slow_fpga: $(TARGET_DIR)/SlowFPGA/SlowFPGA.make VERSION
	mkdir -p $(SLOW_FPGA_BUILD_DIR)
	echo building SlowFPGA
	source $(ISE)  &&  \
	  $(MAKE) -C $(SLOW_FPGA_BUILD_DIR) -f $< \
	  TOP=$(TOP) SRC_DIR=$(TARGET_DIR)/SlowFPGA AUTOGEN=$(AUTOGEN) \
	  bin
.PHONY: slow_fpga

# Compile slow_load binary for target
$(SLOW_LOAD): $(TARGET_DIR)/etc/slow_load.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -o $@ $(LDLIBS) $<

slow_load : $(SLOW_LOAD)
.PHONY: slow_load

