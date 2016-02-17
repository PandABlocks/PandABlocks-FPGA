onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group TB /panda_sequencer_tb/clk_i
add wave -noupdate -expand -group TB /panda_sequencer_tb/reset_i
add wave -noupdate -expand -group TB /panda_sequencer_tb/inpa_i
add wave -noupdate -expand -group TB /panda_sequencer_tb/inpb_i
add wave -noupdate -expand -group TB /panda_sequencer_tb/inpc_i
add wave -noupdate -expand -group TB /panda_sequencer_tb/inpd_i
add wave -noupdate -expand -group TB /panda_sequencer_tb/PRESCALE
add wave -noupdate -expand -group TB /panda_sequencer_tb/SOFT_GATE
add wave -noupdate -expand -group TB /panda_sequencer_tb/TABLE_START
add wave -noupdate -expand -group TB /panda_sequencer_tb/TABLE_DATA
add wave -noupdate -expand -group TB /panda_sequencer_tb/TABLE_WSTB
add wave -noupdate -expand -group TB /panda_sequencer_tb/TABLE_CYCLE
add wave -noupdate -expand -group TB /panda_sequencer_tb/TABLE_LENGTH
add wave -noupdate -expand -group TB /panda_sequencer_tb/TABLE_LENGTH_WSTB
add wave -noupdate -expand -group TB /panda_sequencer_tb/gate_i
add wave -noupdate -expand -group TB /panda_sequencer_tb/outa_o
add wave -noupdate -expand -group TB -color Red /panda_sequencer_tb/OUTA
add wave -noupdate -expand -group TB /panda_sequencer_tb/outb_o
add wave -noupdate -expand -group TB -color Red /panda_sequencer_tb/OUTB
add wave -noupdate -expand -group TB /panda_sequencer_tb/outc_o
add wave -noupdate -expand -group TB -color Red /panda_sequencer_tb/OUTC
add wave -noupdate -expand -group TB /panda_sequencer_tb/outd_o
add wave -noupdate -expand -group TB -color Red /panda_sequencer_tb/OUTD
add wave -noupdate -expand -group TB /panda_sequencer_tb/oute_o
add wave -noupdate -expand -group TB -color Red /panda_sequencer_tb/OUTE
add wave -noupdate -expand -group TB /panda_sequencer_tb/outf_o
add wave -noupdate -expand -group TB -color Red /panda_sequencer_tb/OUTF
add wave -noupdate -expand -group TB /panda_sequencer_tb/active_o
add wave -noupdate -expand -group TB -color Red /panda_sequencer_tb/ACTIVE
add wave -noupdate -expand -group TB -radix decimal -radixshowbase 0 /panda_sequencer_tb/CUR_FRAME
add wave -noupdate -expand -group TB -radix decimal -radixshowbase 0 /panda_sequencer_tb/TB_CUR_FRAME
add wave -noupdate -expand -group TB -radix decimal -radixshowbase 0 /panda_sequencer_tb/CUR_FCYCLE
add wave -noupdate -expand -group TB -radix decimal -radixshowbase 0 /panda_sequencer_tb/TB_CUR_FCYCLE
add wave -noupdate -expand -group TB -radix decimal -radixshowbase 0 /panda_sequencer_tb/CUR_TCYCLE
add wave -noupdate -expand -group TB -radix decimal -radixshowbase 0 /panda_sequencer_tb/TB_CUR_TCYCLE
add wave -noupdate -expand -group TB /panda_sequencer_tb/uut/seq_sm
add wave -noupdate -expand -group TB -radix decimal -radixshowbase 0 /panda_sequencer_tb/uut/tframe_counter
add wave -noupdate -expand -group TB /panda_sequencer_tb/uut/last_frame
add wave -noupdate -expand -group TB /panda_sequencer_tb/uut/last_fcycle
add wave -noupdate -expand -group TB /panda_sequencer_tb/uut/last_tcycle
add wave -noupdate -expand -group TB /panda_sequencer_tb/uut/ongoing_frame
add wave -noupdate -expand -group TB /panda_sequencer_tb/uut/active
add wave -noupdate -expand /panda_sequencer_tb/uut/current_frame
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/clk_i
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/reset_i
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/current_frame.ph2_time
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/gate_i
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/inpa_i
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/inpb_i
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/inpc_i
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/inpd_i
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/outa_o
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/outb_o
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/outc_o
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/outd_o
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/oute_o
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/outf_o
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/active_o
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/PRESCALE
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/SOFT_GATE
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/TABLE_START
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/TABLE_DATA
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/TABLE_WSTB
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/TABLE_CYCLE
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/TABLE_LENGTH
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/TABLE_LENGTH_WSTB
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/CUR_FCYCLE
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/CUR_TCYCLE
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/next_frame
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/load_next
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/repeat_count
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/frame_count
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/table_count
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/frame_length
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/inp_val
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/out_val
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/current_trig
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/current_trig_valid
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/next_trig
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/next_trig_valid
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/presc_reset
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/presc_ce
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/gate_val
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/gate_prev
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/gate_fall
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/gate_rise
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/table_ready
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/fsm_reset
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/last_frame
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/last_fcycle
add wave -noupdate -expand -group UUT /panda_sequencer_tb/uut/last_tcycle
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/clk_i
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/reset_i
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/load_next_i
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/table_ready_o
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/next_frame_o
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/TABLE_START
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/TABLE_DATA
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/TABLE_WSTB
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/TABLE_LENGTH
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/TABLE_LENGTH_WSTB
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/seq_dout
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/seq_waddr
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/seq_raddr
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/seq_wren
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/seq_di
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/table_ready
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/clk_i
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/reset_i
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/load_next_i
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/table_ready_o
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/next_frame_o
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/TABLE_START
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/TABLE_DATA
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/TABLE_WSTB
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/TABLE_LENGTH
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/TABLE_LENGTH_WSTB
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/seq_dout
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/seq_waddr
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/seq_raddr
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/seq_wren
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/seq_di
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/table_ready
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/clk_i
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/reset_i
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/load_next_i
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/table_ready_o
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/next_frame_o
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/TABLE_START
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/TABLE_DATA
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/TABLE_WSTB
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/TABLE_LENGTH
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/TABLE_LENGTH_WSTB
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/seq_dout
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/seq_waddr
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/seq_raddr
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/seq_wren
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/seq_di
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/table_ready
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/clk_i
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/reset_i
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/load_next_i
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/table_ready_o
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/next_frame_o
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/TABLE_START
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/TABLE_DATA
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/TABLE_WSTB
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/TABLE_LENGTH
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/TABLE_LENGTH_WSTB
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/seq_dout
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/seq_waddr
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/seq_raddr
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/seq_wren
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/seq_di
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/table_ready
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/clk_i
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/reset_i
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/load_next_i
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/table_ready_o
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/next_frame_o
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/TABLE_START
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/TABLE_DATA
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/TABLE_WSTB
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/TABLE_LENGTH
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/TABLE_LENGTH_WSTB
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/seq_dout
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/seq_waddr
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/seq_raddr
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/seq_wren
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/seq_di
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/table_ready
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/clk_i
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/reset_i
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/load_next_i
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/table_ready_o
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/next_frame_o
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/TABLE_START
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/TABLE_DATA
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/TABLE_WSTB
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/TABLE_LENGTH
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/TABLE_LENGTH_WSTB
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/seq_dout
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/seq_waddr
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/seq_raddr
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/seq_wren
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/seq_di
add wave -noupdate -group TABLE /panda_sequencer_tb/uut/sequencer_table/table_ready
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 183
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
WaveRestoreZoom {100004380 ps} {101029067 ps}
