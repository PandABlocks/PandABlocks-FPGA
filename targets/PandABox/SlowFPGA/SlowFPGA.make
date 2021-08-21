# Top-level design name
SYSTEM = slow_top

LIST_FILE = $(SYSTEM).lst

SCR_FILE = $(TOP)/syn/xilinx/$(SYSTEM).scr
UCF_FILE = $(TOP)/syn/constr/$(SYSTEM).ucf

POSTSYN_NETLIST = $(SYSTEM).ngc
NGD_FILE = $(SYSTEM).ngd
MAPPED_NCD_FILE = $(SYSTEM)_map.ncd
ROUTED_NCD_FILE = $(SYSTEM).ncd
PCF_FILE = $(SYSTEM).pcf
TWX_FILE = $(SYSTEM).twx
BIT_FILE = $(SYSTEM).bit
BIN_FILE = $(SYSTEM).bin

VERSION_FILE = slow_version.vhd

# Print the names of unlocked (unconstrainted) IOs
export XIL_PAR_DESIGN_CHECK_VERBOSE=1

bin: $(BIN_FILE)
.PHONY: bin

# We have to take a bit of care when building the list file: it turns out that
# xst can't cope with long file names.
$(LIST_FILE): $(TOP)/syn/xilinx/slow_top.files
	cp $< $@

src_dir :
	ln -sfn $(TOP)/src/hdl $@

MAP_FLAGS = -detail -w -ol high -pr b
PAR_FLAGS = -w -ol high
TRCE_FLAGS = -e 3 -l 3

$(BIT_FILE): VERSION $(LIST_FILE) src_dir
	xst -ifn $(SCR_FILE)
	ngdbuild -uc $(UCF_FILE) $(POSTSYN_NETLIST)
	map $(MAP_FLAGS) $(NGD_FILE) -o $(MAPPED_NCD_FILE) $(PCF_FILE)
	par $(PAR_FLAGS) $(MAPPED_NCD_FILE) $(ROUTED_NCD_FILE) $(PCF_FILE)
	trce $(TRCE_FLAGS) $(ROUTED_NCD_FILE) $(PCF_FILE) -xml $(TWX_FILE)
	bitgen -w $(ROUTED_NCD_FILE)

$(BIN_FILE): $(BIT_FILE)
	promgen -w -p bin -u 0 $<

#####################################################################
# Create VERSION_FILE

VERSION :
	rm -f $(VERSION_FILE)
	echo 'library ieee;' >> $(VERSION_FILE)
	echo 'use ieee.std_logic_1164.all;' >> $(VERSION_FILE)
	echo 'package slow_version is' >> $(VERSION_FILE)
	echo -n 'constant SLOW_FPGA_VERSION: std_logic_vector(31 downto 0)' >> $(VERSION_FILE)
	echo ' := X"$(SHA)";' >> $(VERSION_FILE)
	echo 'end slow_version;' >> $(VERSION_FILE)
.PHONY : VERSION
# ------------------------------------------------------------------------------
# Version symbols for FPGA bitstream generation etc

# Something like 0.1-1-g5539563-dirty
GIT_VERSION := $(shell git describe --abbrev=7 --dirty --always --tags)
# 8 if dirty, 0 if clean
DIRTY_PRE = $(shell \
    python -c "print(8 if '$(GIT_VERSION)'.endswith('dirty') else 0)")
# Something like 85539563
SHA := $(DIRTY_PRE)$(shell git rev-parse --short=7 HEAD)

