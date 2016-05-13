library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;
use work.top_defines.all;

entity sfp_loopback is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    mem_addr_i          : in  std_logic_vector(PAGE_AW-1 downto 0);
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0);
    -- GTX I/O
    GTREFCLK_N          : in  std_logic;
    GTREFCLK_P          : in  std_logic;
    RXN_IN              : in  std_logic_vector(2 downto 0);
    RXP_IN              : in  std_logic_vector(2 downto 0);
    TXN_OUT             : out std_logic_vector(2 downto 0);
    TXP_OUT             : out std_logic_vector(2 downto 0)
);
end sfp_loopback;

architecture rtl of sfp_loopback is

signal LINK1_UP         : std_logic_vector(31 downto 0);
signal ERROR1_COUNT     : std_logic_vector(31 downto 0);
signal LINK2_UP         : std_logic_vector(31 downto 0);
signal ERROR2_COUNT     : std_logic_vector(31 downto 0);
signal LINK3_UP         : std_logic_vector(31 downto 0);
signal ERROR3_COUNT     : std_logic_vector(31 downto 0);

begin

--
-- 2./ GTX Loopback Test
--
sfpgtx_exdes_i : entity work.sfpgtx_exdes
port map (
    Q0_CLK0_GTREFCLK_PAD_N_IN   => GTREFCLK_N,
    Q0_CLK0_GTREFCLK_PAD_P_IN   => GTREFCLK_P,
    drpclk_in_i                 => clk_i,
    LINK1_UP                    => LINK1_UP,
    ERROR1_COUNT                => ERROR1_COUNT,
    LINK2_UP                    => LINK2_UP,
    ERROR2_COUNT                => ERROR2_COUNT,
    LINK3_UP                    => LINK3_UP,
    ERROR3_COUNT                => ERROR3_COUNT,
    RXN_IN                      => RXN_IN,
    RXP_IN                      => RXP_IN,
    TXN_OUT                     => TXN_OUT,
    TXP_OUT                     => TXP_OUT
);

sfp_ctrl : entity work.sfp_ctrl
port map (
    -- Clock and Reset
    clk_i                       => clk_i,
    reset_i                     => reset_i,
    sysbus_i                    => (others => '0'),
    posbus_i                    => (others => (others => '0')),
    -- Block Parameters
    LINK1_UP                    => LINK1_UP,
    ERROR1_COUNT                => ERROR1_COUNT,
    LINK2_UP                    => LINK2_UP,
    ERROR2_COUNT                => ERROR2_COUNT,
    LINK3_UP                    => LINK3_UP,
    ERROR3_COUNT                => ERROR3_COUNT,
    -- Memory Bus Interface
    mem_cs_i                    => mem_cs_i,
    mem_wstb_i                  => mem_wstb_i,
    mem_addr_i                  => mem_addr_i(BLK_AW-1 downto 0),
    mem_dat_i                   => mem_dat_i,
    mem_dat_o                   => mem_dat_o
);

end rtl;

