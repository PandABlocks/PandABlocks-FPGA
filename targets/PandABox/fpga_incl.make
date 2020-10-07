SLOW_FPGA_BUILD_DIR = $(TGT_BUILD_DIR)/SlowFPGA

BITS_PREREQ += slow_fpga

# Build SlowFPGA Firmware target
slow_fpga: $(TARGET_DIR)/SlowFPGA/SlowFPGA.make VERSION
	mkdir -p $(SLOW_FPGA_BUILD_DIR)
	echo building SlowFPGA
	source $(ISE)  &&  \
	  $(MAKE) -C $(SLOW_FPGA_BUILD_DIR) -f $< \
	  TOP=$(TOP) SRC_DIR=$(TARGET_DIR)/SlowFPGA AUTOGEN=$(AUTOGEN) \
	  bin
.PHONY: slow_fpga

