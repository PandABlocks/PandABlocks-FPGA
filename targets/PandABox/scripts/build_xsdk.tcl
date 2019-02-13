# variables to pass in: VIVADO_VER?, 
set BUILD_DIR [lindex $argv 0]
set HWSPEC    [lindex $argv 1]
set DEVTREE_SRC [lindex $argv 2]

sdk set_workspace $BUILD_DIR
sdk create_hw_project -name hw_platform_0 -hwspec $HWSPEC
sdk set_user_repo_path $DEVTREE_SRC
sdk create_bsp_project -name device_tree_bsp_0 -hwproject hw_platform_0 -proc ps7_cortexa9_0 -os device_tree
sdk create_app_project -name fsbl -hwproject hw_platform_0 -proc ps7_cortexa9_0 -os standalone -lang C -app {Zynq FSBL} -bsp fsbl_bsp
sdk build_project
