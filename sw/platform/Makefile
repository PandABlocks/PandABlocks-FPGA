KFILES = Kbuild panda_pcap.c panda_pcap.h

ARCH = arm
COMPILER_PREFIX = arm-xilinx-linux-gnueabi
BINUTILS_DIR = /dls_sw/FPGA/Xilinx/SDK/2015.1/gnu/arm/lin
KDIR := /scratch/tmp/zebra2-rootfs/build/linux

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
