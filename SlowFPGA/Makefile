ifndef TOP
$(error Do not call this make file directly)
endif

VPATH = $(SRC_DIR)


# Top-level design name
SYSTEM = slow_top

LIST_FILE = $(SYSTEM).lst

SCR_FILE = $(SRC_DIR)/syn/xilinx/$(SYSTEM).scr
UCF_FILE = $(SRC_DIR)/syn/constr/$(SYSTEM).ucf

POSTSYN_NETLIST = $(SYSTEM).ngc
NGD_FILE = $(SYSTEM).ngd
MAPPED_NCD_FILE = $(SYSTEM)_map.ncd
ROUTED_NCD_FILE = $(SYSTEM).ncd
PCF_FILE = $(SYSTEM).pcf
TWX_FILE = $(SYSTEM).twx
BIT_FILE = $(SYSTEM).bit
PROM_FILE = $(SYSTEM).mcs


# Custom Project dependant defines
VERSION_FILE = slow_version.vhd


include $(TOP)/SlowFPGA/VERSION


# Print the names of unlocked (unconstrainted) IOs
export XIL_PAR_DESIGN_CHECK_VERBOSE=1


netlist: $(POSTSYN_NETLIST)

bits : $(BIT_FILE)

mcs: $(PROM_FILE)

.PHONY: mcs bits netlist


$(VERSION_FILE): VERSION
	rm -f $@
	echo 'library ieee;' >>$@
	echo 'use ieee.std_logic_1164.all;' >>$@
	echo 'package slow_version is' >>$@
	echo -n 'constant FPGAVersion: std_logic_vector(31 downto 0)' \ >>$@
	echo ' := X"$(FPGA_VER_REGISTER)";' >>$@
	echo 'end slow_version;' >>$@


# We have to take a bit of care when building the list file: it turns out that
# xst can't cope with long file names.
$(LIST_FILE): slow_top.files
	ln -sfn $(TOP) top
	sed "s:^:vhdl work top/:" $< >$@
	echo 'vhdl work slow_version.vhd' >>$@


$(POSTSYN_NETLIST): $(LIST_FILE) $(SCR_FILE) $(VERSION_FILE)
	xst -ifn $(SCR_FILE)


MAP_FLAGS = -detail -w -ol high -pr b
PAR_FLAGS = -w -ol high
TRCE_FLAGS = -e 3 -l 3

$(BIT_FILE): $(POSTSYN_NETLIST) $(UCF_FILE)
	ngdbuild -uc $(UCF_FILE) $(POSTSYN_NETLIST)
	map $(MAP_FLAGS) $(NGD_FILE) -o $(MAPPED_NCD_FILE) $(PCF_FILE)
	par $(PAR_FLAGS) $(MAPPED_NCD_FILE) $(ROUTED_NCD_FILE) $(PCF_FILE)
	trce $(TRCE_FLAGS) $(ROUTED_NCD_FILE) $(PCF_FILE) -xml $(TWX_FILE)
	bitgen -w $(ROUTED_NCD_FILE)

$(PROM_FILE): $(BIT_FILE)
	promgen -w -p mcs -o $@ -u 0 $<
