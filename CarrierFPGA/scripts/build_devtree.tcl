open_hw_design ./panda_ps/panda_ps.sdk/panda_ps_wrapper.hdf
set_repo_path ./bsp
create_sw_design device-tree -os device_tree -proc ps7_cortexa9_0
generate_target -dir my_dts
