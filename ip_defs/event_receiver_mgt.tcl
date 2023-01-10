#
# Create SFP event receiver mgt
create_ip -vlnv [get_ipdefs -filter {NAME == gtwizard}] \
-module_name event_receiver_mgt -dir $BUILD_DIR/

set_property -dict [list \
    CONFIG.identical_val_tx_line_rate {2.5} \
    CONFIG.identical_val_rx_line_rate {2.5} \
    CONFIG.gt0_val {false}                                      \
    CONFIG.gt1_val {true}                                       \
    CONFIG.gt0_val_dec_valid_comma_only {true}                  \
    CONFIG.identical_val_tx_reference_clock {125.000}           \
    CONFIG.gt0_val_tx_data_width {16}                           \
    CONFIG.gt0_val_encoding {8B/10B}                            \
    CONFIG.gt0_val_decoding {8B/10B}                            \
    CONFIG.gt0_val_rxusrclk {RXOUTCLK}                          \
    CONFIG.gt0_val_comma_preset {K28.5}                         \
    CONFIG.gt0_val_port_rxcommadet {true}                       \
    CONFIG.gt0_val_port_rxbyteisaligned {true}                  \
    CONFIG.gt0_val_port_rxbyterealign {true}                    \
    CONFIG.gt0_val_port_rxpcommaalignen {true}                  \
    CONFIG.gt0_val_port_rxmcommaalignen {true}                  \
    CONFIG.gt0_val_port_rxslide {false}                         \
    CONFIG.gt0_val_rxslide_mode {OFF}                           \
    CONFIG.gt1_val_tx_refclk {REFCLK1_Q0}                       \
    CONFIG.gt1_val_rx_refclk {REFCLK1_Q0}                       \
    CONFIG.identical_val_rx_reference_clock {125.000}           \
    CONFIG.gt0_val_tx_line_rate {2.5}                           \
    CONFIG.gt0_val_tx_int_datawidth {20}                        \
    CONFIG.gt0_val_tx_reference_clock {125.000}                 \
    CONFIG.gt0_val_rx_line_rate {2.5}                           \
    CONFIG.gt0_val_rx_data_width {16}                           \
    CONFIG.gt0_val_rx_int_datawidth {20}                        \
    CONFIG.gt0_val_rx_reference_clock {125.000}                 \
    CONFIG.gt0_val_cpll_fbdiv {4}                               \
    CONFIG.gt0_val_port_rxcharisk {true}                        \
    CONFIG.gt0_val_tx_buffer_bypass_mode {Auto}                 \
    CONFIG.gt0_val_rx_buffer_bypass_mode {Auto}                 \
    CONFIG.gt0_val_align_comma_word {Two_Byte_Boundaries}       \
    CONFIG.gt0_val_dfe_mode {LPM-Auto}                          \
    CONFIG.gt0_val_rx_cm_trim {800}                             \
    CONFIG.gt0_val_clk_cor_seq_1_1 {00000000}                   \
    CONFIG.gt0_val_clk_cor_seq_1_2 {00000000}                   \
    CONFIG.gt0_val_clk_cor_seq_1_3 {00000000}                   \
    CONFIG.gt0_val_clk_cor_seq_1_4 {00000000}                   \
    CONFIG.gt0_val_clk_cor_seq_2_1 {00000000}                   \
    CONFIG.gt0_val_clk_cor_seq_2_2 {00000000}                   \
    CONFIG.gt0_val_clk_cor_seq_2_3 {00000000}                   \
    CONFIG.gt0_val_clk_cor_seq_2_4 {00000000}                   \
] [get_ips event_receiver_mgt]

generate_target all [get_files  $BUILD_DIR/event_receiver_mgt/event_receiver_mgt.xci]

