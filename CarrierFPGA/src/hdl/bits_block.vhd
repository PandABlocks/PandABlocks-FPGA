--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : BITS block register interface.
--                There are 4 configuration registers for each soft input.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity bits_block is
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
    zero_o              : out std_logic;
    one_o               : out std_logic;
    bits_a_o            : out std_logic;
    bits_b_o            : out std_logic;
    bits_c_o            : out std_logic;
    bits_d_o            : out std_logic
);
end bits_block;

architecture rtl of bits_block is

signal A                : std_logic_vector(31 downto 0);
signal B                : std_logic_vector(31 downto 0);
signal C                : std_logic_vector(31 downto 0);
signal D                : std_logic_vector(31 downto 0);

begin

--
-- Control System Interface
--
bits_ctrl : entity work.bits_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    sysbus_i            => (others => '0'),
    posbus_i            => (others => (others => '0')),

    mem_cs_i            => mem_cs_i,
    mem_wstb_i          => mem_wstb_i,
    mem_addr_i          => mem_addr_i,
    mem_dat_i           => mem_dat_i,

    A                   => A,
    A_WSTB              => open,
    B                   => B,
    B_WSTB              => open,
    C                   => C,
    C_WSTB              => open,
    D                   => D,
    D_WSTB              => open
);

--
-- Block instantiation.
--
bits_inst  : entity work.bits
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    zero_o              => zero_o,
    one_o               => one_o,
    softa_o             => bits_a_o,
    softb_o             => bits_b_o,
    softc_o             => bits_c_o,
    softd_o             => bits_d_o,

    SOFTA_SET           => A(0),
    SOFTB_SET           => B(0),
    SOFTC_SET           => C(0),
    SOFTD_SET           => D(0)
);

end rtl;

