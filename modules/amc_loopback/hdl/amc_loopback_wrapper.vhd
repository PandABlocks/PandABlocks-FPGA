--------------------------------------------------------------------------------
--  	NAMC - 2020
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Arthur Mariano
--------------------------------------------------------------------------------
--
--  Description : AMC loopback for NAMC-ZYNC-FMC card (port 8-11)
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

signal AMC_gtrefclk         : std_logic;
signal SOFT_RESET           : std_logic;
signal LINK_UP_1            : std_logic_vector(31 downto 0);
signal LINK_UP_2            : std_logic_vector(31 downto 0);
signal LINK_UP_3            : std_logic_vector(31 downto 0);
signal LINK_UP_4            : std_logic_vector(31 downto 0);
signal ERROR_COUNT_1        : std_logic_vector(31 downto 0);
signal ERROR_COUNT_2        : std_logic_vector(31 downto 0);
signal ERROR_COUNT_3        : std_logic_vector(31 downto 0);
signal ERROR_COUNT_4        : std_logic_vector(31 downto 0);

signal AMC_FP_TX8_N            : std_logic;
signal AMC_FP_TX8_P            : std_logic;
signal AMC_FP_TX9_N            : std_logic;
signal AMC_FP_TX9_P            : std_logic;
signal AMC_FP_TX10_N           : std_logic;
signal AMC_FP_TX10_P           : std_logic;
signal AMC_FP_TX11_N           : std_logic;
signal AMC_FP_TX11_P           : std_logic;

begin

AMC_txnobuf8 : obuf
port map (
    I => AMC_FP_TX8_N,
    O => AMC_o.FP_TX8_N
);

AMC_txpobuf8 : obuf
port map (
    I => AMC_FP_TX8_P,
    O => AMC_o.FP_TX8_P
);

AMC_txnobuf9 : obuf
port map (
    I => AMC_FP_TX9_N,
    O => AMC_o.FP_TX9_N
);

AMC_txpobuf9 : obuf
port map (
    I => AMC_FP_TX9_P,
    O => AMC_o.FP_TX9_P
);

AMC_txnobuf10 : obuf
port map (
    I => AMC_FP_TX10_N,
    O => AMC_o.FP_TX10_N
);

AMC_txpobuf10 : obuf
port map (
    I => AMC_FP_TX10_P,
    O => AMC_o.FP_TX10_P
);

AMC_txnobuf11 : obuf
port map (
    I => AMC_FP_TX11_N,
    O => AMC_o.FP_TX11_N
);

AMC_txpobuf11 : obuf
port map (
    I => AMC_FP_TX11_P,
    O => AMC_o.FP_TX11_P
);

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

AMC_gtrefclk<=AMC_i.P8_11_GTREFCLK0;
---------------------------------------------------------------------------
-- AMC FAT PIPE Port 8-11 Loopback Test
---------------------------------------------------------------------------
amcgtx_exdes_i1 : entity work.amcgtx2_exdes
port map (
    Q0_CLK1_GTREFCLK_PAD_IN     => AMC_gtrefclk,
    GTREFCLK                    => open,
    drpclk_in_i                 => clk_i,
    SOFT_RESET                  => SOFT_RESET,
    TRACK_DATA_OUT              => LINK_UP_1,
    ERROR_COUNT                 => ERROR_COUNT_1,
    RXP_IN                      => AMC_i.FP_RX8_P,
    RXN_IN                      => AMC_i.FP_RX8_N,
    TXP_OUT                     => AMC_FP_TX8_P,
    TXN_OUT                     => AMC_FP_TX8_N
);
amcgtx_exdes_i2 : entity work.amcgtx2_exdes
port map (
    Q0_CLK1_GTREFCLK_PAD_IN     => AMC_gtrefclk,
    GTREFCLK                    => open,
    drpclk_in_i                 => clk_i,
    SOFT_RESET                  => SOFT_RESET,
    TRACK_DATA_OUT              => LINK_UP_2,
    ERROR_COUNT                 => ERROR_COUNT_2,
    RXP_IN                      => AMC_i.FP_RX9_P,
    RXN_IN                      => AMC_i.FP_RX9_N,
    TXP_OUT                     => AMC_FP_TX9_P,
    TXN_OUT                     => AMC_FP_TX9_N
);
amcgtx_exdes_i3 : entity work.amcgtx2_exdes
port map (
    Q0_CLK1_GTREFCLK_PAD_IN     => AMC_gtrefclk,
    GTREFCLK                    => open,
    drpclk_in_i                 => clk_i,
    SOFT_RESET                  => SOFT_RESET,
    TRACK_DATA_OUT              => LINK_UP_3,
    ERROR_COUNT                 => ERROR_COUNT_3,
    RXP_IN                      => AMC_i.FP_RX10_P,
    RXN_IN                      => AMC_i.FP_RX10_N,
    TXP_OUT                     => AMC_FP_TX10_P,
    TXN_OUT                     => AMC_FP_TX10_N
);
amcgtx_exdes_i4 : entity work.amcgtx2_exdes
port map (
    Q0_CLK1_GTREFCLK_PAD_IN     => AMC_gtrefclk,
    GTREFCLK                    => open,
    drpclk_in_i                 => clk_i,
    SOFT_RESET                  => SOFT_RESET,
    TRACK_DATA_OUT              => LINK_UP_4,
    ERROR_COUNT                 => ERROR_COUNT_4,
    RXP_IN                      => AMC_i.FP_RX11_P,
    RXN_IN                      => AMC_i.FP_RX11_N,
    TXP_OUT                     => AMC_FP_TX11_P,
    TXN_OUT                     => AMC_FP_TX11_N
);

amc_ctrl : entity work.amc_loopback_ctrl
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    bit_bus_i           => bit_bus_i,
    pos_bus_i           => pos_bus_i,
    -- Block Parameters
    SOFT_RESET          => open,
    SOFT_RESET_WSTB     => SOFT_RESET,
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

