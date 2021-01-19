SLOW_FPGA_BUILD_DIR = $(TGT_BUILD_DIR)/SlowFPGA
SLOW_LOAD = $(TGT_BUILD_DIR)/slow_load
SLOW_BIN = $(TGT_BUILD_DIR)/SlowFPGA/slow_top.bin

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

# Slow FPFA requires VERSION_FILE to be present and correct, but does not check its timestamp,
# as every app contains its own built copy of VERSION_FILE. Instead it uses the PREV_VER file,  
# as we do not want to rebuild the Slow FPGA for each app if nothing else has changed.

$(SLOW_BIN): $(TARGET_DIR)/SlowFPGA/SlowFPGA.make $(PREV_VER) | $(VERSION_FILE)
	mkdir -p $(SLOW_FPGA_BUILD_DIR)
	echo building SlowFPGA
	source $(ISE)  &&  \
	  $(MAKE) -C $(SLOW_FPGA_BUILD_DIR) -f $< \
	  TOP=$(TOP) SRC_DIR=$(TARGET_DIR)/SlowFPGA AUTOGEN=$(AUTOGEN) \
	  bin

slow_fpga : $(SLOW_BIN)
.PHONY: slow_fpga

# Compile slow_load binary for target
$(SLOW_LOAD): $(TARGET_DIR)/etc/slow_load.c
	. $(VIVADO) && $(CC) $(CFLAGS) -o $@ $<


slow_load : $(SLOW_LOAD)
.PHONY: slow_load

