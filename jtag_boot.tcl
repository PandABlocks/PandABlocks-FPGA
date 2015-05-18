# Scripting Linux Start-up using JTAG

connect arm hw
rst
source ./output/panda_ps/panda_ps.sdk/hw_platform_0/ps7_init.tcl
fpga -f ./output/panda_top.bit
ps7_init
ps7_post_config
dow /home/iu42/hardware/trunk/FPGA/PandA-Motion-Project/PandaLinux/images/u-boot.elf
con

# NOT USED
#dow ../src/zxl_ps/zxl_ps.sdk/SDK/SDK_Export/zxl_fsbl/Debug/zxl_fsbl.elf
#con
#exec sleep 5
#stop

