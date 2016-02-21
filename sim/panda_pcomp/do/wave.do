onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group TB -radix decimal /panda_pcomp_tb/clk_i
add wave -noupdate -expand -group TB -radix decimal /panda_pcomp_tb/reset_i
add wave -noupdate -expand -group TB -radix decimal /panda_pcomp_tb/enable_i
add wave -noupdate -expand -group TB -radix decimal -radixshowbase 0 /panda_pcomp_tb/posn_i
add wave -noupdate -expand -group TB -radix decimal -radixshowbase 0 /panda_pcomp_tb/START
add wave -noupdate -expand -group TB -radix decimal -radixshowbase 0 /panda_pcomp_tb/STEP
add wave -noupdate -expand -group TB -radix decimal -radixshowbase 0 /panda_pcomp_tb/WIDTH
add wave -noupdate -expand -group TB -radix decimal -radixshowbase 0 /panda_pcomp_tb/NUM
add wave -noupdate -expand -group TB -radix decimal /panda_pcomp_tb/RELATIVE
add wave -noupdate -expand -group TB -radix decimal /panda_pcomp_tb/DIR
add wave -noupdate -expand -group TB -radix decimal -radixshowbase 0 /panda_pcomp_tb/FLTR_DELTAT
add wave -noupdate -expand -group TB -radix decimal -radixshowbase 0 /panda_pcomp_tb/FLTR_THOLD
add wave -noupdate -expand -group TB -radix decimal /panda_pcomp_tb/err_o
add wave -noupdate -expand -group TB -radix decimal /panda_pcomp_tb/act_o
add wave -noupdate -expand -group TB -color Red -radix decimal /panda_pcomp_tb/ACT
add wave -noupdate -expand -group TB -radix decimal /panda_pcomp_tb/pulse_o
add wave -noupdate -expand -group TB -color Red -radix decimal /panda_pcomp_tb/PULSE
add wave -noupdate -radix decimal -radixshowbase 0 /panda_pcomp_tb/uut/posn
add wave -noupdate -radix decimal -radixshowbase 0 /panda_pcomp_tb/uut/posn_prev
add wave -noupdate -radix decimal -radixshowbase 0 /panda_pcomp_tb/FLTR_DELTAT
add wave -noupdate /panda_pcomp_tb/uut/FLTR_DELTAT_WSTB
add wave -noupdate -radix unsigned -radixshowbase 0 /panda_pcomp_tb/uut/deltat_counter
add wave -noupdate /panda_pcomp_tb/uut/fltr_reset
add wave -noupdate -radix decimal -radixshowbase 0 /panda_pcomp_tb/uut/fltr_counter
add wave -noupdate -radix decimal -radixshowbase 0 /panda_pcomp_tb/uut/puls_dir
add wave -noupdate -group UUT -radix decimal /panda_pcomp_tb/uut/clk_i
add wave -noupdate -group UUT -radix decimal /panda_pcomp_tb/uut/reset_i
add wave -noupdate -group UUT -radix decimal /panda_pcomp_tb/uut/enable_i
add wave -noupdate -group UUT -radix decimal /panda_pcomp_tb/uut/posn_i
add wave -noupdate -group UUT -radix decimal /panda_pcomp_tb/uut/START
add wave -noupdate -group UUT -radix decimal /panda_pcomp_tb/uut/STEP
add wave -noupdate -group UUT -radix decimal /panda_pcomp_tb/uut/WIDTH
add wave -noupdate -group UUT -radix decimal /panda_pcomp_tb/uut/NUM
add wave -noupdate -group UUT -radix decimal /panda_pcomp_tb/uut/RELATIVE
add wave -noupdate -group UUT -radix decimal /panda_pcomp_tb/uut/DIR
add wave -noupdate -group UUT -radix decimal /panda_pcomp_tb/uut/FLTR_DELTAT
add wave -noupdate -group UUT -radix decimal /panda_pcomp_tb/uut/FLTR_DELTAT_WSTB
add wave -noupdate -group UUT -radix decimal /panda_pcomp_tb/uut/FLTR_THOLD
add wave -noupdate -group UUT -radix decimal /panda_pcomp_tb/uut/act_o
add wave -noupdate -group UUT -radix decimal /panda_pcomp_tb/uut/err_o
add wave -noupdate -group UUT -radix decimal /panda_pcomp_tb/uut/pulse_o
add wave -noupdate -group UUT -radix decimal /panda_pcomp_tb/uut/pcomp_fsm
add wave -noupdate -group UUT -radix decimal /panda_pcomp_tb/uut/enable_prev
add wave -noupdate -group UUT -radix decimal /panda_pcomp_tb/uut/enable_rise
add wave -noupdate -group UUT -radix decimal /panda_pcomp_tb/uut/enable_fall
add wave -noupdate -group UUT -radix decimal /panda_pcomp_tb/uut/posn_latched
add wave -noupdate -group UUT -radix decimal /panda_pcomp_tb/uut/dir_matched
add wave -noupdate -group UUT -radix decimal /panda_pcomp_tb/uut/puls_start
add wave -noupdate -group UUT -radix decimal /panda_pcomp_tb/uut/puls_width
add wave -noupdate -group UUT -radix decimal /panda_pcomp_tb/uut/puls_step
add wave -noupdate -group UUT -radix decimal /panda_pcomp_tb/uut/puls_counter
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 150
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
WaveRestoreZoom {801584144 ps} {802964646 ps}
