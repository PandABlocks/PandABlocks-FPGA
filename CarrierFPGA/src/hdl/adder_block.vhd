--------------------------------------------------------------------------------
--  File:       adder_block.vhd
--  Desc:       Position compare output pulse generator
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;

entity adder_block is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(BLK_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    -- Block inputs
    posbus_i            : in  posbus_t;
    -- Output pulse
    out_o               : out std_logic_vector(31 downto 0)
);
end adder_block;

architecture rtl of adder_block is

signal inpa             : std_logic_vector(31 downto 0);
signal inpb             : std_logic_vector(31 downto 0);
signal inpc             : std_logic_vector(31 downto 0);
signal inpd             : std_logic_vector(31 downto 0);

signal SCALE            : std_logic_vector(31 downto 0);

begin

--
-- Control System Interface
--
adder_ctrl : entity work.adder_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    sysbus_i            => (others => '0'),
    posbus_i            => posbus_i,
    inpa_o              => inpa,
    inpb_o              => inpb,
    inpc_o              => inpc,
    inpd_o              => inpd,

    mem_cs_i            => mem_cs_i,
    mem_wstb_i          => mem_wstb_i,
    mem_addr_i          => mem_addr_i,
    mem_dat_i           => mem_dat_i,
    mem_dat_o           => open,

    SCALE               => SCALE,
    SCALE_WSTB          => open
);

-- LUT Block Core Instantiation
adder : entity work.adder
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    inpa_i              => inpa,
    inpb_i              => inpb,
    inpc_i              => inpc,
    inpd_i              => inpd,
    out_o               => out_o,

    SCALE               => SCALE(1 downto 0)
);

end rtl;

