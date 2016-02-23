onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group TB -radix decimal /panda_pcomp_tb/clk_i
add wave -noupdate -expand -group TB -radix decimal /panda_pcomp_tb/reset_i
add wave -noupdate -expand -group TB -radix decimal /panda_pcomp_tb/enable_i
add wave -noupdate -expand -group TB -radix decimal -radixshowbase 0 /panda_pcomp_tb/posn_i
add wave -noupdate -expand -group TB -radix decimal -radixshowbase 0 /panda_pcomp_tb/START
add wave -noupdate -expand -group TB -radix decimal -radixshowbase 0 /panda_pcomp_tb/STEP
add wave -noupdate -expand -group TB -radix decimal -radixshowbase 0 /panda_pcomp_tb/WIDTH
add wave -noupdate -expand -group TB -radix decimal /panda_pcomp_tb/NUM
add wave -noupdate -expand -group TB -radix decimal /panda_pcomp_tb/RELATIVE
add wave -noupdate -expand -group TB -radix decimal /panda_pcomp_tb/DIR
add wave -noupdate -expand -group TB -radix decimal /panda_pcomp_tb/DELTAP
add wave -noupdate -expand -group TB -radix decimal /panda_pcomp_tb/err_o
add wave -noupdate -expand -group TB -color Red -radix decimal /panda_pcomp_tb/ERR
add wave -noupdate -expand -group TB -radix decimal /panda_pcomp_tb/act_o
add wave -noupdate -expand -group TB -color Red -radix decimal /panda_pcomp_tb/ACT
add wave -noupdate -expand -group TB -radix decimal /panda_pcomp_tb/pulse_o
add wave -noupdate -expand -group TB -color Red -radix decimal /panda_pcomp_tb/PULSE
add wave -noupdate -expand -group TB -radix decimal /panda_pcomp_tb/uut/pcomp_fsm
add wave -noupdate -radix decimal -radixshowbase 0 /panda_pcomp_tb/uut/current_crossing
add wave -noupdate -radix decimal -radixshowbase 0 /panda_pcomp_tb/uut/next_crossing
add wave -noupdate -expand -group UUT -radix decimal /panda_pcomp_tb/uut/clk_i
add wave -noupdate -expand -group UUT -radix decimal /panda_pcomp_tb/uut/reset_i
add wave -noupdate -expand -group UUT -radix decimal /panda_pcomp_tb/uut/enable_i
add wave -noupdate -expand -group UUT -radix decimal /panda_pcomp_tb/uut/posn_i
add wave -noupdate -expand -group UUT -radix decimal /panda_pcomp_tb/uut/START
add wave -noupdate -expand -group UUT -radix decimal /panda_pcomp_tb/uut/STEP
add wave -noupdate -expand -group UUT -radix decimal /panda_pcomp_tb/uut/WIDTH
add wave -noupdate -expand -group UUT -radix decimal /panda_pcomp_tb/uut/NUM
add wave -noupdate -expand -group UUT -radix decimal /panda_pcomp_tb/uut/RELATIVE
add wave -noupdate -expand -group UUT -radix decimal /panda_pcomp_tb/uut/DIR
add wave -noupdate -expand -group UUT -radix decimal /panda_pcomp_tb/uut/DELTAP
add wave -noupdate -expand -group UUT -radix decimal /panda_pcomp_tb/uut/act_o
add wave -noupdate -expand -group UUT -radix decimal /panda_pcomp_tb/uut/err_o
add wave -noupdate -expand -group UUT -radix decimal /panda_pcomp_tb/uut/pulse_o
add wave -noupdate -expand -group UUT -radix decimal /panda_pcomp_tb/uut/enable_prev
add wave -noupdate -expand -group UUT -radix decimal /panda_pcomp_tb/uut/enable_rise
add wave -noupdate -expand -group UUT -radix decimal /panda_pcomp_tb/uut/enable_fall
add wave -noupdate -expand -group UUT -radix decimal /panda_pcomp_tb/uut/posn
add wave -noupdate -expand -group UUT -radix decimal /panda_pcomp_tb/uut/posn_latched
add wave -noupdate -expand -group UUT -radix decimal /panda_pcomp_tb/uut/puls_start
add wave -noupdate -expand -group UUT -radix decimal /panda_pcomp_tb/uut/puls_width
add wave -noupdate -expand -group UUT -radix decimal /panda_pcomp_tb/uut/puls_step
add wave -noupdate -expand -group UUT -radix decimal /panda_pcomp_tb/uut/puls_deltap
add wave -noupdate -expand -group UUT -radix decimal /panda_pcomp_tb/uut/puls_counter
add wave -noupdate -expand -group UUT -radix decimal /panda_pcomp_tb/uut/posn_error
add wave -noupdate -expand -group UUT -radix decimal /panda_pcomp_tb/uut/pulse
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 162
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
WaveRestoreZoom {200278727 ps} {201019585 ps}
