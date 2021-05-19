env set bootargs console=ttyPS0,115200 rdinit=/init ro
fatload mmc 0:1 $kernel_addr_r uImage
fatload mmc 0:1 $ramdisk_addr_r uinitramfs
fatload mmc 0:1 $fdt_addr_r devicetree.dtb
bootm $kernel_addr_r $ramdisk_addr_r $fdt_addr_r
