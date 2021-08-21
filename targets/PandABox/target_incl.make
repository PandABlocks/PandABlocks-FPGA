SLOW_FPGA_BUILD_DIR = $(TGT_BUILD_DIR)/SlowFPGA
SLOW_BIN = $(TGT_BUILD_DIR)/SlowFPGA/slow_top.bin

BITS_PREREQ += slow_fpga

# Build SlowFPGA Firmware target

# Slow FPFA requires VERSION_FILE to be present and correct, but does not check its timestamp,
# as every app contains its own built copy of VERSION_FILE. Instead it uses the $(VER) file,  
# as we do not want to rebuild the Slow FPGA for each app if nothing else has changed.

$(SLOW_BIN): $(TARGET_DIR)/SlowFPGA/SlowFPGA.make $(VER) | $(VERSION_FILE)
	mkdir -p $(SLOW_FPGA_BUILD_DIR)
	echo building SlowFPGA
	source $(ISE)  &&  \
	  $(MAKE) -C $(SLOW_FPGA_BUILD_DIR) -f $< \
	  TOP=$(TARGET_DIR)/SlowFPGA AUTOGEN=$(AUTOGEN) \
	  bin

slow_fpga : $(SLOW_BIN)
.PHONY: slow_fpga

