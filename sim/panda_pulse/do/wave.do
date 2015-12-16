onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group Testbench -radix decimal /panda_pulse_tb/clk_i
add wave -noupdate -expand -group Testbench -radix decimal /panda_pulse_tb/inp_i
add wave -noupdate -expand -group Testbench -radix decimal /panda_pulse_tb/out_o
add wave -noupdate -expand -group Testbench -radix decimal /panda_pulse_tb/rst_i
add wave -noupdate -expand -group Testbench -radix decimal /panda_pulse_tb/DELAY
add wave -noupdate -expand -group Testbench -radix decimal /panda_pulse_tb/WIDTH
add wave -noupdate -expand -group Testbench -radix decimal /panda_pulse_tb/FORCE_RST
add wave -noupdate -expand -group Testbench -radix decimal /panda_pulse_tb/out_expected
add wave -noupdate -expand -group Testbench -radix decimal /panda_pulse_tb/perr_o
add wave -noupdate -expand -group Testbench -radix decimal /panda_pulse_tb/perr_expected
add wave -noupdate -expand -group Testbench -radix decimal /panda_pulse_tb/ERR_OVERFLOW
add wave -noupdate -expand -group Testbench -radix decimal /panda_pulse_tb/ERR_OVERFLOW_EXPECTED
add wave -noupdate -expand -group Testbench -radix decimal /panda_pulse_tb/ERR_PERIOD
add wave -noupdate -expand -group Testbench -radix decimal /panda_pulse_tb/ERR_PERIOD_EXPECTED
add wave -noupdate -expand -group Testbench -radix decimal /panda_pulse_tb/QUEUE
add wave -noupdate -expand -group Testbench -radix decimal /panda_pulse_tb/QUEUE_EXPECTED
add wave -noupdate -expand -group Testbench -radix decimal /panda_pulse_tb/MISSED_CNT
add wave -noupdate -expand -group Testbench -radix decimal /panda_pulse_tb/MISSED_CNT_EXPECTED
add wave -noupdate -expand -group Testbench -radix decimal /panda_pulse_tb/timestamp
add wave -noupdate -expand -group Testbench -radix decimal /panda_pulse_tb/is_file_end
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/clk_i
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/pulse
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/pulse_value
add wave -noupdate -group Pulse -radix decimal -radixshowbase 0 /panda_pulse_tb/uut/pulse_ts
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/inp_i
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/reset
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/pulse_queue_wstb
add wave -noupdate -group Pulse -radix decimal -radixshowbase 0 /panda_pulse_tb/uut/pulse_queue_din
add wave -noupdate -group Pulse -radix decimal -radixshowbase 0 /panda_pulse_tb/uut/pulse_queue_dout
add wave -noupdate -group Pulse -radix decimal -radixshowbase 0 /panda_pulse_tb/uut/timestamp
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/rst_i
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/perr_o
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/DELAY
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/WIDTH
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/FORCE_RST
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/ERR_OVERFLOW
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/ERR_PERIOD
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/QUEUE
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/MISSED_CNT
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/pulse_fsm
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/period_error
add wave -noupdate -group Pulse -radix decimal -radixshowbase 0 /panda_pulse_tb/uut/queue_din
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/pulse_queue_full
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/pulse_queue_empty
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/pulse_queue_rstb
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/out_o
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/pulse_queue_data_count
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/inp_rise
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/inp_fall
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/ongoing_pulse
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/DELAY_prev
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/WIDTH_prev
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/config_reset
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/inp_prev
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/inp_rise_prev
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/timestamp_prev
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/delta_T
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/missed_pulses
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/is_first_pulse
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/value
add wave -noupdate -group Pulse -radix decimal /panda_pulse_tb/uut/is_DELAY_zero
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 312
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
WaveRestoreZoom {0 ps} {1750731 ps}
