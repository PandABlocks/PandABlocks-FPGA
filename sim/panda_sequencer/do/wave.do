onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /panda_sequencer_tb/uut/clk_i
add wave -noupdate /panda_sequencer_tb/uut/gate_i
add wave -noupdate /panda_sequencer_tb/uut/inpa_i
add wave -noupdate /panda_sequencer_tb/uut/outa_o
add wave -noupdate /panda_sequencer_tb/uut/outb_o
add wave -noupdate /panda_sequencer_tb/uut/outc_o
add wave -noupdate /panda_sequencer_tb/uut/outd_o
add wave -noupdate /panda_sequencer_tb/uut/oute_o
add wave -noupdate /panda_sequencer_tb/uut/outf_o
add wave -noupdate /panda_sequencer_tb/uut/active_o
add wave -noupdate -radix unsigned -radixshowbase 0 /panda_sequencer_tb/uut/seq_raddr
add wave -noupdate /panda_sequencer_tb/uut/seq_cur_frame.repeats
add wave -noupdate -radix decimal -childformat {{/panda_sequencer_tb/uut/repeat_count(31) -radix decimal} {/panda_sequencer_tb/uut/repeat_count(30) -radix decimal} {/panda_sequencer_tb/uut/repeat_count(29) -radix decimal} {/panda_sequencer_tb/uut/repeat_count(28) -radix decimal} {/panda_sequencer_tb/uut/repeat_count(27) -radix decimal} {/panda_sequencer_tb/uut/repeat_count(26) -radix decimal} {/panda_sequencer_tb/uut/repeat_count(25) -radix decimal} {/panda_sequencer_tb/uut/repeat_count(24) -radix decimal} {/panda_sequencer_tb/uut/repeat_count(23) -radix decimal} {/panda_sequencer_tb/uut/repeat_count(22) -radix decimal} {/panda_sequencer_tb/uut/repeat_count(21) -radix decimal} {/panda_sequencer_tb/uut/repeat_count(20) -radix decimal} {/panda_sequencer_tb/uut/repeat_count(19) -radix decimal} {/panda_sequencer_tb/uut/repeat_count(18) -radix decimal} {/panda_sequencer_tb/uut/repeat_count(17) -radix decimal} {/panda_sequencer_tb/uut/repeat_count(16) -radix decimal} {/panda_sequencer_tb/uut/repeat_count(15) -radix decimal} {/panda_sequencer_tb/uut/repeat_count(14) -radix decimal} {/panda_sequencer_tb/uut/repeat_count(13) -radix decimal} {/panda_sequencer_tb/uut/repeat_count(12) -radix decimal} {/panda_sequencer_tb/uut/repeat_count(11) -radix decimal} {/panda_sequencer_tb/uut/repeat_count(10) -radix decimal} {/panda_sequencer_tb/uut/repeat_count(9) -radix decimal} {/panda_sequencer_tb/uut/repeat_count(8) -radix decimal} {/panda_sequencer_tb/uut/repeat_count(7) -radix decimal} {/panda_sequencer_tb/uut/repeat_count(6) -radix decimal} {/panda_sequencer_tb/uut/repeat_count(5) -radix decimal} {/panda_sequencer_tb/uut/repeat_count(4) -radix decimal} {/panda_sequencer_tb/uut/repeat_count(3) -radix decimal} {/panda_sequencer_tb/uut/repeat_count(2) -radix decimal} {/panda_sequencer_tb/uut/repeat_count(1) -radix decimal} {/panda_sequencer_tb/uut/repeat_count(0) -radix decimal}} -radixshowbase 1 -subitemconfig {/panda_sequencer_tb/uut/repeat_count(31) {-height 17 -radix decimal -radixshowbase 0} /panda_sequencer_tb/uut/repeat_count(30) {-height 17 -radix decimal -radixshowbase 0} /panda_sequencer_tb/uut/repeat_count(29) {-height 17 -radix decimal -radixshowbase 0} /panda_sequencer_tb/uut/repeat_count(28) {-height 17 -radix decimal -radixshowbase 0} /panda_sequencer_tb/uut/repeat_count(27) {-height 17 -radix decimal -radixshowbase 0} /panda_sequencer_tb/uut/repeat_count(26) {-height 17 -radix decimal -radixshowbase 0} /panda_sequencer_tb/uut/repeat_count(25) {-height 17 -radix decimal -radixshowbase 0} /panda_sequencer_tb/uut/repeat_count(24) {-height 17 -radix decimal -radixshowbase 0} /panda_sequencer_tb/uut/repeat_count(23) {-height 17 -radix decimal -radixshowbase 0} /panda_sequencer_tb/uut/repeat_count(22) {-height 17 -radix decimal -radixshowbase 0} /panda_sequencer_tb/uut/repeat_count(21) {-height 17 -radix decimal -radixshowbase 0} /panda_sequencer_tb/uut/repeat_count(20) {-height 17 -radix decimal -radixshowbase 0} /panda_sequencer_tb/uut/repeat_count(19) {-height 17 -radix decimal -radixshowbase 0} /panda_sequencer_tb/uut/repeat_count(18) {-height 17 -radix decimal -radixshowbase 0} /panda_sequencer_tb/uut/repeat_count(17) {-height 17 -radix decimal -radixshowbase 0} /panda_sequencer_tb/uut/repeat_count(16) {-height 17 -radix decimal -radixshowbase 0} /panda_sequencer_tb/uut/repeat_count(15) {-height 17 -radix decimal -radixshowbase 0} /panda_sequencer_tb/uut/repeat_count(14) {-height 17 -radix decimal -radixshowbase 0} /panda_sequencer_tb/uut/repeat_count(13) {-height 17 -radix decimal -radixshowbase 0} /panda_sequencer_tb/uut/repeat_count(12) {-height 17 -radix decimal -radixshowbase 0} /panda_sequencer_tb/uut/repeat_count(11) {-height 17 -radix decimal -radixshowbase 0} /panda_sequencer_tb/uut/repeat_count(10) {-height 17 -radix decimal -radixshowbase 0} /panda_sequencer_tb/uut/repeat_count(9) {-height 17 -radix decimal -radixshowbase 0} /panda_sequencer_tb/uut/repeat_count(8) {-height 17 -radix decimal -radixshowbase 0} /panda_sequencer_tb/uut/repeat_count(7) {-height 17 -radix decimal -radixshowbase 0} /panda_sequencer_tb/uut/repeat_count(6) {-height 17 -radix decimal -radixshowbase 0} /panda_sequencer_tb/uut/repeat_count(5) {-height 17 -radix decimal -radixshowbase 0} /panda_sequencer_tb/uut/repeat_count(4) {-height 17 -radix decimal -radixshowbase 0} /panda_sequencer_tb/uut/repeat_count(3) {-height 17 -radix decimal -radixshowbase 0} /panda_sequencer_tb/uut/repeat_count(2) {-height 17 -radix decimal -radixshowbase 0} /panda_sequencer_tb/uut/repeat_count(1) {-height 17 -radix decimal -radixshowbase 0} /panda_sequencer_tb/uut/repeat_count(0) {-height 17 -radix decimal -radixshowbase 0}} /panda_sequencer_tb/uut/repeat_count
add wave -noupdate /panda_sequencer_tb/uut/last_frame_repeat
add wave -noupdate /panda_sequencer_tb/uut/last_table_repeat
add wave -noupdate -expand /panda_sequencer_tb/uut/seq_cur_frame
add wave -noupdate /panda_sequencer_tb/uut/seq_next_frame
add wave -noupdate /panda_sequencer_tb/uut/seq_dout
add wave -noupdate /panda_sequencer_tb/uut/seq_load_enable
add wave -noupdate /panda_sequencer_tb/uut/seq_load_enable_prev
add wave -noupdate /panda_sequencer_tb/uut/seq_load_init
add wave -noupdate /panda_sequencer_tb/uut/seq_load_done
add wave -noupdate /panda_sequencer_tb/uut/seq_waddr
add wave -noupdate /panda_sequencer_tb/uut/seq_wraddr
add wave -noupdate /panda_sequencer_tb/uut/seq_rdaddr
add wave -noupdate /panda_sequencer_tb/uut/tframe_counter
add wave -noupdate /panda_sequencer_tb/uut/frame_count
add wave -noupdate /panda_sequencer_tb/uut/table_count
add wave -noupdate /panda_sequencer_tb/uut/seq_sm
add wave -noupdate /panda_sequencer_tb/uut/seq_trig
add wave -noupdate /panda_sequencer_tb/uut/seq_trig_prev
add wave -noupdate /panda_sequencer_tb/uut/seq_trig_pulse
add wave -noupdate /panda_sequencer_tb/uut/inp_val
add wave -noupdate /panda_sequencer_tb/uut/out_val
add wave -noupdate /panda_sequencer_tb/uut/presc_reset
add wave -noupdate /panda_sequencer_tb/uut/presc_ce
add wave -noupdate /panda_sequencer_tb/uut/seq_wren
add wave -noupdate /panda_sequencer_tb/uut/seq_di
add wave -noupdate /panda_sequencer_tb/uut/FORCE_GATE
add wave -noupdate /panda_sequencer_tb/uut/PRESCALE
add wave -noupdate /panda_sequencer_tb/uut/SOFT_GATE
add wave -noupdate /panda_sequencer_tb/uut/TABLE_PUSH_START
add wave -noupdate /panda_sequencer_tb/uut/TABLE_PUSH_DATA
add wave -noupdate /panda_sequencer_tb/uut/TABLE_PUSH_WSTB
add wave -noupdate /panda_sequencer_tb/uut/TABLE_REPEAT
add wave -noupdate /panda_sequencer_tb/uut/TABLE_LENGTH
add wave -noupdate /panda_sequencer_tb/uut/TABLE_LENGTH_DWORD
add wave -noupdate /panda_sequencer_tb/uut/CUR_FCYCLES
add wave -noupdate /panda_sequencer_tb/uut/CUR_FRAME
add wave -noupdate /panda_sequencer_tb/uut/CUR_STATE
add wave -noupdate /panda_sequencer_tb/uut/CUR_TCYCLE
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 225
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
WaveRestoreZoom {0 ps} {525 us}
