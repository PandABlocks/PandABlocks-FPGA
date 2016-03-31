include ../CONFIG
include ../../VERSION

all:
	@echo "----------------------------------------"
	@echo "Makefile to build UDP Sniffer firmware :"
	@echo "----------------------------------------"
	@echo "Run make with any of the following targets"
	@echo " "
	@echo " netlist  : Generates the netlist for the project for given target board "
	@echo " bits     : Run implementation tools to generate the bitstream
	@echo " download : Downloads the bitstream onto the board"
	@echo " program  : Generate mcs file from bitstream and program the PROM"

netlist: $(POSTSYN_NETLIST)

bits : $(BIT_FILE)

mcs: $(PROM_FILE)

$(VERSION_FILE): ../../VERSION
	rm -rf $@
	echo 'library ieee;' >>$@
	echo 'use ieee.std_logic_1164.all;' >>$@
	echo 'package slow_version is' >>$@
	echo -n 'constant FPGAVersion: std_logic_vector(31 downto 0)' \ >>$@
	echo ' := X"$(FPGA_VER_REGISTER)";' >>$@
	echo 'end slow_version;' >>$@

$(NETLIST_DIR):
	mkdir $(NETLIST_DIR)

$(COREGEN_NGC_FILES):
#	coregen -b $(IP_DIR)/ila.xco
#	coregen -b $(IP_DIR)/icon.xco

$(LIST_FILE):
	cat ../xilinx/$(LIST_FILE) >> $(LIST_FILE)

$(SCR_FILE):
	cat ../xilinx/$(SCR_FILE) >> $(SCR_FILE)

$(POSTSYN_NETLIST): $(NETLIST_DIR) $(COREGEN_NGC_FILES) $(LIST_FILE) $(SCR_FILE) $(VERSION_FILE)
	xst -ifn $(SCR_FILE)
#	precision -rtlplus -shell -file ../syn_scripts/slow_top.tcl

$(UCF_FILE):
	cat ../constr/$(UCF_FILE) > $(UCF_FILE)

NGDBUILD_FLAGS = -sd $(NETLIST_DIR)
MAP_FLAGS = -detail -w -ol high -pr b
PAR_FLAGS = -w -ol high
TRCE_FLAGS = -e 3 -l 3

$(BIT_FILE): $(POSTSYN_NETLIST) $(UCF_FILE)
	ngdbuild -uc $(UCF_FILE) $(POSTSYN_NETLIST) $(NGDBUILD_FLAGS)
	map $(MAP_FLAGS) $(NGD_FILE) -o $(MAPPED_NCD_FILE) $(PCF_FILE)
	par $(PAR_FLAGS) $(MAPPED_NCD_FILE) $(ROUTED_NCD_FILE) $(PCF_FILE)
	trce $(TRCE_FLAGS) $(ROUTED_NCD_FILE) $(PCF_FILE) -xml $(TWX_FILE)
	bitgen -w $(ROUTED_NCD_FILE)

download:
	ssh iu42@$(JTAG_PC) 'cd $(CURDIR);$(XILINX)/bin/lin64/impact -batch ../xilinx/loadFPGA.cmd'

$(PROM_FILE): $(BIT_FILE)
	promgen -w -p mcs -o $(PROM_FILE) -u 0 $(BIT_FILE)

program: $(PROM_FILE)
	impact -batch ../xilinx/loadPROM.cmd

hwclean:
	rm -rf $(NETLIST_DIR)
	rm -rf $(VERSION_FILE)
	rm -rf ../run/*

clean:
	rm -rf $(VERSION_FILE)
	rm -rf ../run/*
