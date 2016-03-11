onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix decimal /pcap_core_tb/ACTIVE
add wave -noupdate -radix decimal /pcap_core_tb/uut/pcap_core_inst/pcap_actv_o
add wave -noupdate -radix decimal -radixshowbase 0 /pcap_core_tb/DATA
add wave -noupdate -radix decimal /pcap_core_tb/DATA_WSTB
add wave -noupdate -radix decimal -radixshowbase 0 /pcap_core_tb/pcap_dat_o
add wave -noupdate -radix decimal /pcap_core_tb/pcap_dat_valid_o
add wave -noupdate -radix decimal /pcap_core_tb/ERROR


