ifndef TOP
$(error Do not call this make file directly)
endif

VPATH = $(SRC_DIR)

# Top-level design name
SYSTEM = slow_top

LIST_FILE = $(SYSTEM).lst

SCR_FILE = $(SRC_DIR)/syn/xilinx/$(SYSTEM).scr
NETLIST_DIR = $(SRC_DIR)/syn/implementation
UCF_FILE = $(SRC_DIR)/syn/constr/$(SYSTEM)-$(BOARD).ucf

POSTSYN_NETLIST = $(SYSTEM).ngc
NGD_FILE = $(SYSTEM).ngd
MAPPED_NCD_FILE = $(SYSTEM)_map.ncd
ROUTED_NCD_FILE = $(SYSTEM).ncd
PCF_FILE = $(SYSTEM).pcf
TWX_FILE = $(SYSTEM).twx
BIT_FILE = $(SYSTEM).bit
PROM_FILE = $(SYSTEM).mcs

VERSION_FILE = $(TOP)/SlowFPGA/src/hdl/slow_version.vhd

include $(TOP)/SLOW_VERSION

# Print the names of unlocked (unconstrainted) IOs
export XIL_PAR_DESIGN_CHECK_VERBOSE=1

bits : $(BIT_FILE)

mcs: $(PROM_FILE)

.PHONY: mcs bits netlist

VERSION :
	rm -f $(VERSION_FILE)
	echo 'library ieee;' >> $(VERSION_FILE)
	echo 'use ieee.std_logic_1164.all;' >> $(VERSION_FILE)
	echo 'package slow_version is' >> $(VERSION_FILE)
	echo -n 'constant SLOW_FPGA_VERSION: std_logic_vector(31 downto 0)' \ >> $(VERSION_FILE)
	echo ' := X"$(FIRMWARE)";' >> $(VERSION_FILE)
	echo 'end slow_version;' >> $(VERSION_FILE)


# We have to take a bit of care when building the list file: it turns out that
# xst can't cope with long file names.
$(LIST_FILE): slow_top.files
	ln -sfn $(TOP) top
	sed "s:^:vhdl work top/:" $< >$@

MAP_FLAGS = -detail -w -ol high -pr b
PAR_FLAGS = -w -ol high
TRCE_FLAGS = -e 3 -l 3

$(BIT_FILE): VERSION $(LIST_FILE)
	xst -ifn $(SCR_FILE)
	ngdbuild -sd $(NETLIST_DIR) -uc $(UCF_FILE) $(POSTSYN_NETLIST)
	map $(MAP_FLAGS) $(NGD_FILE) -o $(MAPPED_NCD_FILE) $(PCF_FILE)
	par $(PAR_FLAGS) $(MAPPED_NCD_FILE) $(ROUTED_NCD_FILE) $(PCF_FILE)
	trce $(TRCE_FLAGS) $(ROUTED_NCD_FILE) $(PCF_FILE) -xml $(TWX_FILE)
	bitgen -w $(ROUTED_NCD_FILE)


$(PROM_FILE): $(BIT_FILE)
	promgen -w -p hex -o slow_top.hex -u 0 $<
	$(TOP)/tools/virtexHex2Bin < slow_top.hex > slow_top.bin
	promgen -w -p mcs -o $@ -u 0 $<
