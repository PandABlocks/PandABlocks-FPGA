onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /panda_status_tb/uut/clk_i
add wave -noupdate /panda_status_tb/uut/reset_i
add wave -noupdate /panda_status_tb/uut/mem_addr_i
add wave -noupdate /panda_status_tb/uut/mem_cs_i
add wave -noupdate /panda_status_tb/uut/mem_wstb_i
add wave -noupdate /panda_status_tb/uut/mem_dat_i
add wave -noupdate /panda_status_tb/uut/sysbus_i
add wave -noupdate /panda_status_tb/uut/sysbus
add wave -noupdate /panda_status_tb/uut/sysbus_prev
add wave -noupdate /panda_status_tb/uut/sysbus_change
add wave -noupdate /panda_status_tb/uut/sysbus_change_clear
add wave -noupdate /panda_status_tb/uut/index
add wave -noupdate /panda_status_tb/uut/mem_rstb_i
add wave -noupdate /panda_status_tb/uut/sysbus_rstb
add wave -noupdate /panda_status_tb/uut/sysbus_change_clear(0)
add wave -noupdate /panda_status_tb/uut/sysbus_change(0)
add wave -noupdate /panda_status_tb/uut/sysbus_prev(0)
add wave -noupdate /panda_status_tb/uut/sysbus(0)
add wave -noupdate /panda_status_tb/uut/mem_dat_o
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 226
configure wave -valuecolwidth 52
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {2533742 ps} {2721461 ps}
