#
# Xilinx ISE Environment
#
PLATFORM = $(shell uname -m)

ifeq ($(PLATFORM),x86_64)
	ISE=source /dls_sw/apps/FPGA/Xilinx/14.7/ISE_DS/settings64.sh > /dev/null
endif

ifeq ($(PLATFORM),i686)
	ISE=source /dls_sw/apps/FPGA/Xilinx/14.7/ISE_DS/settings32.sh > /dev/null
endif

PATH := $(PATH):/dls_sw/apps/FPGA/Precision/2012b/Mgc_home/bin

#
# Print the names of unlocked (unconstrainted) IOs
#
export XIL_PAR_DESIGN_CHECK_VERBOSE=1

#
# Name of the PC to be used for programming the FPGA
#
JTAG_PC=pc0001

#
# Hardware Platform Settings
#

main: clean
	$(ISE) && make -C syn/run -f ../Makefile bits
	$(ISE) && make -C syn/run -f ../Makefile mcs

picoblaze:
	util/picoblaze/Picoasm/picoasm -i rtl/slow_pblaze/assembler/slow_pblaze_rom.psm -t rtl/slow_pblaze/assembler/ROM_form.vhd -d rtl/slow_pblaze/vhdl

download:
	$(ISE) && make -C syn/run -f ../Makefile JTAG_PC=$(JTAG_PC) download

program:
	$(ISE) && make -C syn/run -f ../Makefile JTAG_PC=$(JTAG_PC) program

hwclean:
	$(ISE) && make -C syn/run -f ../Makefile hwclean
	$(ISE) && make -C syn/run -f ../Makefile clean

clean:
	$(ISE) && make -C syn/run -f ../Makefile clean
