library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;
use work.top_defines.all;

entity sfp_loopback_wrapper is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- System Bus
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

    -- SFP Interface
    SFP                 : view MGT_Module
);
end sfp_loopback_wrapper;

architecture rtl of sfp_loopback_wrapper is

--signal test_clocks      : std_logic;
signal LINK_UP         : std_logic_vector(31 downto 0);
signal ERROR_COUNT     : std_logic_vector(31 downto 0);
signal FREQ_VAL         : std_logic_vector(31 downto 0);
signal GTREFCLK         : std_logic;
signal MAC_LO           : std_logic_vector(31 downto 0);-- := (others => '0');
signal MAC_HI           : std_logic_vector(31 downto 0);-- := (others => '0');
signal SOFT_RESET       : std_logic;
signal SFP_LOS_VEC      : std_logic_vector(31 downto 0) := (others => '0');

signal TXN, TXP             : std_logic;

begin

txnobuf : obuf
port map (
    I => TXN,
    O => SFP.TXN_OUT
);

txpobuf : obuf
port map (
    I => TXP,
    O => SFP.TXP_OUT
);

--
-- 2./ GTX Loopback Test
--
sfpgtx_exdes_i : entity work.sfpgtx_exdes
port map (
    Q0_CLK0_GTREFCLK_PAD_IN       => SFP.GTREFCLK,
    GTREFCLK                    => GTREFCLK,
    drpclk_in_i                 => clk_i,
    SOFT_RESET                  => SOFT_RESET,
    LINK_UP                    => LINK_UP,
    ERROR_COUNT                => ERROR_COUNT,
    RXN_IN                      => SFP.RXN_IN,
    RXP_IN                      => SFP.RXP_IN,
    TXN_OUT                     => TXN,
    TXP_OUT                     => TXP
);

---------------------------------------------------------------------------
-- FMC Clocks Frequency Counter
---------------------------------------------------------------------------

--test_clocks(0) <= GTREFCLK;

freq_counter_inst : entity work.freq_counter
generic map( NUM => 1)
port map (
    refclk          => clk_i,
    reset           => reset_i,
    test_clocks(0)     => GTREFCLK,
    freq_out(0)        => FREQ_VAL
);

SFP_LOS_VEC <= (0 => SFP.SFP_LOS, others => '0');

MAC_HI(23 downto 0) <= SFP.MAC_ADDR(47 downto 24);
MAC_LO(23 downto 0) <= SFP.MAC_ADDR(23 downto 0);

---------------------------------------------------------------------------
-- FMC CSR Interface
---------------------------------------------------------------------------
sfp_ctrl : entity work.sfp_loopback_ctrl
port map (
    -- Clock and Reset
    clk_i                       => clk_i,
    reset_i                     => reset_i,
    bit_bus_i                   => bit_bus_i,
    pos_bus_i                   => pos_bus_i,
    -- Block Parameters
    SFP_LOS                    => SFP_LOS_VEC,
    LINK_UP                    => LINK_UP,
    ERROR_COUNT                => ERROR_COUNT,
    SFP_CLK                   => FREQ_VAL,
    SFP_MAC_LO                 => MAC_LO,
    SFP_MAC_HI                 => MAC_HI,
    SOFT_RESET                  => open,
    SOFT_RESET_WSTB             => SOFT_RESET,
    -- Memory Bus Interface
    read_strobe_i               => read_strobe_i,
    read_address_i              => read_address_i(BLK_AW-1 downto 0),
    read_data_o                 => read_data_o,
    read_ack_o                  => read_ack_o,

    write_strobe_i              => write_strobe_i,
    write_address_i             => write_address_i(BLK_AW-1 downto 0),
    write_data_i                => write_data_i,
    write_ack_o                 => write_ack_o
);

end rtl;

