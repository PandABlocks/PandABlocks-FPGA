onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /panda_pcomp_tb/uut/clk_i
add wave -noupdate /panda_pcomp_tb/uut/reset_i
add wave -noupdate /panda_pcomp_tb/uut/enable_i
add wave -noupdate /panda_pcomp_tb/uut/mem_cs_i
add wave -noupdate /panda_pcomp_tb/uut/mem_wstb_i
add wave -noupdate /panda_pcomp_tb/uut/mem_addr_i
add wave -noupdate /panda_pcomp_tb/uut/mem_dat_i
add wave -noupdate /panda_pcomp_tb/uut/mem_dat_o
add wave -noupdate -format Analog-Step -height 100 -max 5000.0000000000009 -min -5000.0 /panda_pcomp_tb/uut/posn_i
add wave -noupdate /panda_pcomp_tb/uut/act_o
add wave -noupdate /panda_pcomp_tb/uut/pulse_o
add wave -noupdate /panda_pcomp_tb/uut/enable
add wave -noupdate /panda_pcomp_tb/uut/enable_prev
add wave -noupdate /panda_pcomp_tb/uut/enable_rise
add wave -noupdate /panda_pcomp_tb/uut/state
add wave -noupdate /panda_pcomp_tb/uut/start
add wave -noupdate /panda_pcomp_tb/uut/width
add wave -noupdate /panda_pcomp_tb/uut/posn
add wave -noupdate /panda_pcomp_tb/uut/posn_prev
add wave -noupdate /panda_pcomp_tb/uut/posn_latched
add wave -noupdate /panda_pcomp_tb/uut/puls_start
add wave -noupdate /panda_pcomp_tb/uut/puls_width
add wave -noupdate /panda_pcomp_tb/uut/puls_step
add wave -noupdate /panda_pcomp_tb/uut/puls_dir
add wave -noupdate /panda_pcomp_tb/uut/PCOMP_START
add wave -noupdate /panda_pcomp_tb/uut/PCOMP_STEP
add wave -noupdate /panda_pcomp_tb/uut/PCOMP_WIDTH
add wave -noupdate /panda_pcomp_tb/uut/PCOMP_NUM
add wave -noupdate /panda_pcomp_tb/uut/PCOMP_RELATIVE
add wave -noupdate /panda_pcomp_tb/uut/PCOMP_DIR
add wave -noupdate /panda_pcomp_tb/uut/PCOMP_FLTR_DELTAT
add wave -noupdate /panda_pcomp_tb/uut/PCOMP_FLTR_THOLD
add wave -noupdate -radix unsigned /panda_pcomp_tb/uut/fltr_counter
add wave -noupdate /panda_pcomp_tb/uut/posn_trans
add wave -noupdate /panda_pcomp_tb/uut/puls_counter
add wave -noupdate /panda_pcomp_tb/uut/posn_dir
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
configure wave -namecolwidth 166
configure wave -valuecolwidth 100
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
WaveRestoreZoom {2961670 ns} {2973691 ns}
