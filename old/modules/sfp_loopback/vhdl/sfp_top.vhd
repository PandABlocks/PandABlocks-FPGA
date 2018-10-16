library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;
use work.top_defines.all;

entity sfp_top is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- System Bus
    sysbus_i            : in  std_logic_vector(SBUSW-1 downto 0);
    sfp_inputs_o        : out std_logic_vector(15 downto 0) := (others=>'0');
    sfp_data_o          : out std32_array(15 downto 0) := (others=>(others=>'0'));
    
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
    SFP_interface       : inout SFP_interface
);
end sfp_top;

architecture rtl of sfp_top is

signal test_clocks      : std_logic_vector(0 downto 0);
signal LINK_UP         : std_logic_vector(31 downto 0);
signal ERROR_COUNT     : std_logic_vector(31 downto 0);
signal FREQ_VAL         : std32_array(0 downto 0);
signal GTREFCLK         : std_logic;
signal SOFT_RESET       : std_logic;
signal SFP_LOS_VEC      : std_logic_vector(31 downto 0) := (others => '0');

begin

-- Acknowledgement to AXI Lite interface
write_ack_o <= '1';

read_ack_delay : entity work.delay_line
generic map (DW => 1)
port map (
    clk_i       => clk_i,
    data_i(0)   => read_strobe_i,
    data_o(0)   => read_ack_o,
    DELAY       => RD_ADDR2ACK
);

--
-- 2./ GTX Loopback Test
--
sfpgtx_exdes_i : entity work.sfpgtx_exdes
port map (
    Q0_CLK0_GTREFCLK_PAD_IN       => SFP_interface.GTREFCLK,
    GTREFCLK                    => GTREFCLK,
    drpclk_in_i                 => clk_i,
    SOFT_RESET                  => SOFT_RESET,
    LINK_UP                    => LINK_UP,
    ERROR_COUNT                => ERROR_COUNT,
    RXN_IN                      => SFP_interface.RXN_IN,
    RXP_IN                      => SFP_interface.RXP_IN,
    TXN_OUT                     => SFP_interface.TXN_OUT,
    TXP_OUT                     => SFP_interface.TXP_OUT
);

---------------------------------------------------------------------------
-- FMC Clocks Frequency Counter
---------------------------------------------------------------------------

test_clocks(0) <= GTREFCLK;

freq_counter_inst : entity work.freq_counter
generic map( NUM => 1)
port map (
    refclk          => clk_i,
    reset           => reset_i,
    test_clocks     => test_clocks,
    freq_out        => FREQ_VAL
);

SFP_LOS_VEC <= (0 => SFP_interface.SFP_LOS, others => '0');

---------------------------------------------------------------------------
-- FMC CSR Interface
---------------------------------------------------------------------------
sfp_ctrl : entity work.sfp_ctrl
port map (
    -- Clock and Reset
    clk_i                       => clk_i,
    reset_i                     => reset_i,
    sysbus_i                    => (others => '0'),
    posbus_i                    => (others => (others => '0')),
    -- Block Parameters
    SFP_LOS                    => SFP_LOS_VEC,
    LINK_UP                    => LINK_UP,
    ERROR_COUNT                => ERROR_COUNT,
    SFP_CLK                   => FREQ_VAL(0),
    SOFT_RESET                  => open,
    SOFT_RESET_WSTB             => SOFT_RESET,
    -- Memory Bus Interface
    read_strobe_i               => read_strobe_i,
    read_address_i              => read_address_i(BLK_AW-1 downto 0),
    read_data_o                 => read_data_o,
    read_ack_o                  => open,

    write_strobe_i              => write_strobe_i,
    write_address_i             => write_address_i(BLK_AW-1 downto 0),
    write_data_i                => write_data_i,
    write_ack_o                 => open
);

end rtl;

