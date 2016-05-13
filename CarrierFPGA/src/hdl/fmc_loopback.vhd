library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;
use work.top_defines.all;

entity fmc_loopback is
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
    -- LA I/O
    fmc_la_p            : inout std_logic_vector(33 downto 0);
    fmc_la_n            : inout std_logic_vector(33 downto 0);
    -- GTX I/O
    TXP_OUT             : out   std_logic;
    TXN_OUT             : out   std_logic;
    RXP_IN              : in    std_logic;
    RXN_IN              : in    std_logic;
    GTREFCLK_P          : in    std_logic;
    GTREFCLK_N          : in    std_logic
);
end fmc_loopback;

architecture rtl of fmc_loopback is

signal la_counter       : unsigned(16 downto 0) := (others => '0');
signal la_p_compare     : std_logic_vector(16 downto 0);
signal la_n_compare     : std_logic_vector(16 downto 0);
signal LINK_UP          : std_logic_vector(31 downto 0);
signal ERROR_COUNT      : std_logic_vector(31 downto 0);
signal LA_P_ERROR       : std_logic_vector(31 downto 0);
signal LA_N_ERROR       : std_logic_vector(31 downto 0);

begin

--
-- 1./ LA Pins loopback Test
--

-- Output counter on LA pins.
fmc_la_p(16 downto 0) <= std_logic_vector(la_counter);
fmc_la_n(16 downto 0) <= std_logic_vector(la_counter);
fmc_la_p(33 downto 17) <= (others => 'Z');
fmc_la_n(33 downto 17) <= (others => 'Z');

process(clk_i)
begin
    if rising_edge(clk_i) then
        -- Free running counter when enabled.
        la_counter <= la_counter + 1;

        -- Comparator on LA lines individually, and set '1' for un-matching
        -- bits.
        la_p_compare <= fmc_la_p(33 downto 17) xor
                        std_logic_vector(la_counter);
        la_n_compare <= fmc_la_n(33 downto 17) xor
                        std_logic_vector(la_counter);
    end if;
end process;

LA_P_ERROR <= ZEROS(15) & la_p_compare;
LA_N_ERROR <= ZEROS(15) & la_n_compare;

--
-- 2./ GTX Loopback Test
--
fmcgtx_exdes_i : entity work.fmcgtx_exdes
port map (
    Q0_CLK1_GTREFCLK_PAD_N_IN   => GTREFCLK_N,
    Q0_CLK1_GTREFCLK_PAD_P_IN   => GTREFCLK_P,
    drpclk_in_i                 => clk_i,
    TRACK_DATA_OUT              => LINK_UP,
    ERROR_COUNT                 => ERROR_COUNT,
    RXN_IN                      => RXN_IN,
    RXP_IN                      => RXP_IN,
    TXN_OUT                     => TXN_OUT,
    TXP_OUT                     => TXP_OUT
);

fmc_ctrl : entity work.fmc_ctrl
port map (
    -- Clock and Reset
    clk_i                       => clk_i,
    reset_i                     => reset_i,
    sysbus_i                    => (others => '0'),
    posbus_i                    => (others => (others => '0')),
    -- Block Parameters
    LINK_UP                     => LINK_UP,
    ERROR_COUNT                 => ERROR_COUNT,
    LA_P_ERROR                  => LA_P_ERROR,
    LA_N_ERROR                  => LA_N_ERROR,
    -- Memory Bus Interface
    mem_cs_i                    => mem_cs_i,
    mem_wstb_i                  => mem_wstb_i,
    mem_addr_i                  => mem_addr_i(BLK_AW-1 downto 0),
    mem_dat_i                   => mem_dat_i,
    mem_dat_o                   => mem_dat_o
);

end rtl;

