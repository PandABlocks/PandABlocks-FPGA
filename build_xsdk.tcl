sdk set_workspace output/panda_ps/panda_ps.sdk/
sdk create_hw_project -name hw_platform_0 -hwspec output/panda_ps_wrapper.hdf
sdk set_user_repo_path output/bsp/device-tree-xlnx-xilinx-v2015.1
#sdk create_bsp_project -name device_tree_bsp_0 -hwproject hw_platform_0 -proc ps7_cortexa9_0 -os device_tree
sdk create_bsp_project -name device_tree_bsp_0 -hwproject hw_platform_0 -mss configs/device-tree/xilinx-v2015.1/pzed-z7030/system.mss
sdk create_app_project -name fsbl -hwproject hw_platform_0 -proc ps7_cortexa9_0 -os standalone -lang C -app {Zynq FSBL} -bsp fsbl_bsp
sdk build_project
