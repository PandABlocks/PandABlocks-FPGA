--------------------------------------------------------------------------------
--  	NAMC - 2020
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Arthur Mariano
--------------------------------------------------------------------------------
--
--  Description : AMC loopback for NAMC with eMCH
--
--                
--                                
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.support.all;
use work.top_defines.all;

entity amc_loopback_wrapper is
port (
    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Standard AMC Block ports, do not add to or delete
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Bus Inputs
    bit_bus_i           : in  bit_bus_t;
    pos_bus_i           : in  pos_bus_t;
    -- Memory Bus Interface
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(PAGE_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(PAGE_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic;
    AMC_i               : in  amc_input_interface;
    AMC_o               : out amc_output_interface

);
end amc_loopback_wrapper;

architecture rtl of amc_loopback_wrapper is

signal probe0               : std_logic_vector(31 downto 0);
signal clock_en             : std_logic;
signal test_clocks          : std_logic_vector(3 downto 0);
signal FREQ_VAL             : std32_array(3 downto 0);
signal GTREFCLK             : std_logic;
signal FMC_PRSNT_DW         : std_logic_vector(31 downto 0);
signal MAC_LO           	: std_logic_vector(31 downto 0);
signal MAC_HI           	: std_logic_vector(31 downto 0);
signal SOFT_RESET           : std_logic;
signal LOOP_PERIOD_WSTB     : std_logic;
signal LOOP_PERIOD          : std_logic_vector(31 downto 0);
signal LINK_UP_1            : std_logic_vector(31 downto 0);
signal LINK_UP_2            : std_logic_vector(31 downto 0);
signal LINK_UP_3            : std_logic_vector(31 downto 0);
signal LINK_UP_4            : std_logic_vector(31 downto 0);
signal ERROR_COUNT_1        : std_logic_vector(31 downto 0);
signal ERROR_COUNT_2        : std_logic_vector(31 downto 0);
signal ERROR_COUNT_3        : std_logic_vector(31 downto 0);
signal ERROR_COUNT_4        : std_logic_vector(31 downto 0);
--signal PCIe_B112_TX0_P		: std_logic;
--signal PCIe_B112_TX0_N		: std_logic;
--signal PCIe_B112_RX0_P		: std_logic;
--signal PCIe_B112_RX0_N		: std_logic;
--signal PCIe_B112_TX1_P		: std_logic;
--signal PCIe_B112_TX1_N		: std_logic;
--signal PCIe_B112_RX1_P		: std_logic;
--signal PCIe_B112_RX1_N		: std_logic;

attribute MARK_DEBUG        : string;
attribute MARK_DEBUG of probe0  : signal is "true";


begin

-- Acknowledgement to AXI Lite interface
write_ack_o <= '1';

read_ack_delay : entity work.delay_line
generic map (DW => 1)
port map (
    clk_i       => clk_i,
    data_i(0)   => read_strobe_i,
    data_o(0)   => read_ack_o,
    DELAY_i     => RD_ADDR2ACK
);

-- Multiplex read data out from multiple instantiations

-- Generate prescaled clock for internal counter
frame_presc : entity work.prescaler
port map (
    clk_i       => clk_i,
    reset_i     => LOOP_PERIOD_WSTB,
    PERIOD      => LOOP_PERIOD,
    pulse_o     => clock_en
);

---------------------------------------------------------------------------
-- PCIe Loopback Test
---------------------------------------------------------------------------
amcgtx_exdes_i1 : entity work.amcgtx_exdes
port map (
    Q0_CLK1_GTREFCLK_PAD_IN     => AMC_i.GTREFCLK1,
    GTREFCLK                    => open,--GTREFCLK,
    drpclk_in_i                 => clk_i,
    SOFT_RESET                  => SOFT_RESET,
    TRACK_DATA_OUT              => LINK_UP_1,
    ERROR_COUNT                 => ERROR_COUNT_1,
    RXP_IN                      => AMC_i.FP_RX4_P,
    RXN_IN                      => AMC_i.FP_RX4_N,
    TXP_OUT                     => AMC_o.FP_TX4_P,
    TXN_OUT                     => AMC_o.FP_TX4_N
);
amcgtx_exdes_i2 : entity work.amcgtx_exdes
port map (
    Q0_CLK1_GTREFCLK_PAD_IN     => AMC_i.GTREFCLK1,
    GTREFCLK                    => open,
    drpclk_in_i                 => clk_i,
    SOFT_RESET                  => SOFT_RESET,
    TRACK_DATA_OUT              => LINK_UP_2,
    ERROR_COUNT                 => ERROR_COUNT_2,
    RXP_IN                      => AMC_i.FP_RX5_P,
    RXN_IN                      => AMC_i.FP_RX5_N,
    TXP_OUT                     => AMC_o.FP_TX5_P,
    TXN_OUT                     => AMC_o.FP_TX5_N
);
amcgtx_exdes_i3 : entity work.amcgtx_exdes
port map (
    Q0_CLK1_GTREFCLK_PAD_IN     => AMC_i.GTREFCLK1,
    GTREFCLK                    => open,
    drpclk_in_i                 => clk_i,
    SOFT_RESET                  => SOFT_RESET,
    TRACK_DATA_OUT              => LINK_UP_3,
    ERROR_COUNT                 => ERROR_COUNT_3,
    RXP_IN                      => AMC_i.FP_RX6_P,
    RXN_IN                      => AMC_i.FP_RX6_N,
    TXP_OUT                     => AMC_o.FP_TX6_P,
    TXN_OUT                     => AMC_o.FP_TX6_N
);
amcgtx_exdes_i4 : entity work.amcgtx_exdes
port map (
    Q0_CLK1_GTREFCLK_PAD_IN     => AMC_i.GTREFCLK1,
    GTREFCLK                    => open,
    drpclk_in_i                 => clk_i,
    SOFT_RESET                  => SOFT_RESET,
    TRACK_DATA_OUT              => LINK_UP_4,
    ERROR_COUNT                 => ERROR_COUNT_4,
    RXP_IN                      => AMC_i.FP_RX7_P,
    RXN_IN                      => AMC_i.FP_RX7_N,
    TXP_OUT                     => AMC_o.FP_TX7_P,
    TXN_OUT                     => AMC_o.FP_TX7_N
);


freq_counter_inst : entity work.freq_counter
generic map ( NUM => 4)
port map (
    refclk          => clk_i,
    reset           => reset_i,
    test_clocks     => test_clocks,
    freq_out        => FREQ_VAL
);

amc_ctrl : entity work.amc_loopback_ctrl
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    bit_bus_i           => bit_bus_i,
    pos_bus_i           => pos_bus_i,
    -- Block Parameters
    GTREFCLK            => FREQ_VAL(0),
    EXT_CLK             => FREQ_VAL(3),
    SOFT_RESET          => open,
    SOFT_RESET_WSTB     => SOFT_RESET,
    LOOP_PERIOD         => LOOP_PERIOD,
    LOOP_PERIOD_WSTB    => LOOP_PERIOD_WSTB,
    LINK_UP_1			=> LINK_UP_1,
    LINK_UP_2			=> LINK_UP_2,
    LINK_UP_3			=> LINK_UP_3,
    LINK_UP_4			=> LINK_UP_4,
    ERROR_COUNT_1       => ERROR_COUNT_1,
    ERROR_COUNT_2       => ERROR_COUNT_2,
    ERROR_COUNT_3       => ERROR_COUNT_3,
    ERROR_COUNT_4       => ERROR_COUNT_4,
    -- Memory Bus Interface
    read_strobe_i       => read_strobe_i,
    read_address_i      => read_address_i(BLK_AW-1 downto 0),
    read_data_o         => read_data_o,
    read_ack_o          => open, 

    write_strobe_i      => write_strobe_i,
    write_address_i     => write_address_i(BLK_AW-1 downto 0),
    write_data_i        => write_data_i,
    write_ack_o         => open
);

end rtl;

