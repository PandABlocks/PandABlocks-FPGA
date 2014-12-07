KFILES = Kbuild panda_pcap.c panda_pcap.h

ARCH = arm
COMPILER_PREFIX = arm-xilinx-linux-gnueabi
BINUTILS_DIR = /dls_sw/FPGA/Xilinx/SDK/2014.2/gnu/arm/lin
KDIR := /scratch/targetOS/Zynq/build/linux-xlnx-xilinx-v2014.2.01

export CROSS_COMPILE = $(BINUTILS_DIR)/bin/$(COMPILER_PREFIX)-
export ARCH

all: clean install

kbuild:
	mkdir -p kbuild
	$(foreach file,$(KFILES), ln -s ../$(file) kbuild;)

kbuild/panda_pcap.ko: panda_pcap.c kbuild
	make -C $(KDIR) M=$(CURDIR)/kbuild modules

install: kbuild/panda_pcap.ko
	cp kbuild/panda_pcap.ko /dls_sw/work/hardware

clean:
	rm -rf kbuild
