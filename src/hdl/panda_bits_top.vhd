--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Top-level for BITS block instantiations.
--                There is only 1 (one) BITS block in the design.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity panda_bits_top is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    mem_addr_i          : in  std_logic_vector(PAGE_AW-1 downto 0);
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_rstb_i          : in  std_logic;
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0);
    -- Output pulses
    zero_o              : out std_logic;
    one_o               : out std_logic;
    soft_o              : out std_logic_vector(3 downto 0)
);
end panda_bits_top;

architecture rtl of panda_bits_top is

begin

-- Unused outputs.
mem_dat_o <= (others => '0');

--
-- Instantiate BITS Blocks :
--  There are BITS_NUM amount of encoders on the board
--
panda_bits_block : entity work.panda_bits_block
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    mem_cs_i            => mem_cs_i,
    mem_wstb_i          => mem_wstb_i,
    mem_addr_i          => mem_addr_i(BLK_AW-1 downto 0),
    mem_dat_i           => mem_dat_i,

    zero_o              => zero_o,
    one_o               => one_o,
    soft_o              => soft_o
);

end rtl;
