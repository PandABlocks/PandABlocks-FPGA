sdk set_workspace ./panda_top/panda_top.sdk/
sdk create_hw_project -name hw_platform_0 -hwspec ./panda_top_wrapper.hdf
sdk set_user_repo_path ./bsp/device-tree-xlnx-xilinx-v2015.1
#sdk create_bsp_project -name device_tree_bsp_0 -hwproject hw_platform_0 -proc ps7_cortexa9_0 -os device_tree
sdk create_app_project -name fsbl -hwproject hw_platform_0 -proc ps7_cortexa9_0 -os standalone -lang C -app {Zynq FSBL} -bsp fsbl_bsp
sdk create_bsp_project -name device_tree_bsp_0 -hwproject hw_platform_0 -mss ../../CarrierFPGA/configs/device-tree/xilinx-v2015.1/pzed-z7030/system.mss
sdk build_project
