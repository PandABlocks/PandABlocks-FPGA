--------------------------------------------------------------------------------
--  File:       clocks_block.vhd
--  Desc:       Position compare output pulse generator
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;

entity clocks_block is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(BLK_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    -- Block outputs
    clocks_a_o          : out std_logic;
    clocks_b_o          : out std_logic;
    clocks_c_o          : out std_logic;
    clocks_d_o          : out std_logic
);
end clocks_block;

architecture rtl of clocks_block is

signal CLOCKA_PERIOD    : std_logic_vector(31 downto 0) := (others => '0');
signal CLOCKB_PERIOD    : std_logic_vector(31 downto 0) := (others => '0');
signal CLOCKC_PERIOD    : std_logic_vector(31 downto 0) := (others => '0');
signal CLOCKD_PERIOD    : std_logic_vector(31 downto 0) := (others => '0');

signal A_PERIOD_WSTB    : std_logic;
signal B_PERIOD_WSTB    : std_logic;
signal C_PERIOD_WSTB    : std_logic;
signal D_PERIOD_WSTB    : std_logic;

signal reset            : std_logic;

begin

--
-- Control System Interface
--
clocks_ctrl : entity work.clocks_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    sysbus_i            => (others => '0'),
    posbus_i            => (others => (others => '0')),

    mem_cs_i            => mem_cs_i,
    mem_wstb_i          => mem_wstb_i,
    mem_addr_i          => mem_addr_i,
    mem_dat_i           => mem_dat_i,
    mem_dat_o           => open,

    A_PERIOD            => CLOCKA_PERIOD,
    A_PERIOD_WSTB       => A_PERIOD_WSTB,
    B_PERIOD            => CLOCKB_PERIOD,
    B_PERIOD_WSTB       => B_PERIOD_WSTB,
    C_PERIOD            => CLOCKC_PERIOD,
    C_PERIOD_WSTB       => C_PERIOD_WSTB,
    D_PERIOD            => CLOCKD_PERIOD,
    D_PERIOD_WSTB       => D_PERIOD_WSTB
);

reset <= reset_i or A_PERIOD_WSTB or B_PERIOD_WSTB or
            C_PERIOD_WSTB or D_PERIOD_WSTB;

--
-- Block instantiation.
--
clocks_inst  : entity work.clocks
port map (
    clk_i               => clk_i,
    reset_i             => reset,

    clocka_o            => clocks_a_o,
    clockb_o            => clocks_b_o,
    clockc_o            => clocks_c_o,
    clockd_o            => clocks_d_o,

    CLOCKA_PERIOD       => CLOCKA_PERIOD,
    CLOCKB_PERIOD       => CLOCKB_PERIOD,
    CLOCKC_PERIOD       => CLOCKC_PERIOD,
    CLOCKD_PERIOD       => CLOCKD_PERIOD
);

end rtl;

