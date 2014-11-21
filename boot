# Scripting Linux Start-up using JTAG

connect arm hw
rst -slcr
#dow ../src/zxl_ps/zxl_ps.sdk/SDK/SDK_Export/zxl_fsbl/Debug/zxl_fsbl.elf
#con
#exec sleep 5
#stop
source ./output/panda_ps/panda_ps.sdk/panda_ps/ps7_init.tcl
fpga -f ./output/panda_top.bit
ps7_init
ps7_post_config
dow /home/iu42/targetOS/zynq/u-boot-xlnx/u-boot
con
