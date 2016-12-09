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
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(BLK_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(BLK_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic;
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

    read_strobe_i       => read_strobe_i,
    read_address_i      => read_address_i,
    read_data_o         => read_data_o,
    read_ack_o          => read_ack_o,

    write_strobe_i      => write_strobe_i,
    write_address_i     => write_address_i,
    write_data_i        => write_data_i,
    write_ack_o         => write_ack_o,

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

