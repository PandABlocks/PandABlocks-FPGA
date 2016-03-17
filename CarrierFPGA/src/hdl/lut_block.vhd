--------------------------------------------------------------------------------
--  File:       lut_block.vhd
--  Desc:       Position compare output pulse generator
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity lut_block is
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
    sysbus_i            : in  sysbus_t;
    -- Output pulse
    out_o               : out std_logic
);
end lut_block;

architecture rtl of lut_block is

signal FUNC             : std_logic_vector(31 downto 0);
signal FUNC_WSTB        : std_logic;

signal inpa             : std_logic;
signal inpb             : std_logic;
signal inpc             : std_logic;
signal inpd             : std_logic;
signal inpe             : std_logic;

begin

--
-- Control System Interface
--
lut_ctrl : entity work.lut_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    sysbus_i            => sysbus_i,
    posbus_i            => (others => (others => '0')),
    inpa_o              => inpa,
    inpb_o              => inpb,
    inpc_o              => inpc,
    inpd_o              => inpd,
    inpe_o              => inpe,

    mem_cs_i            => mem_cs_i,
    mem_wstb_i          => mem_wstb_i,
    mem_addr_i          => mem_addr_i,
    mem_dat_i           => mem_dat_i,
    mem_dat_o           => open,

    FUNC                => FUNC,
    FUNC_WSTB           => open

);


-- LUT Block Core Instantiation
lut : entity work.lut
port map (
    clk_i       => clk_i,
    reset_i     => reset_i,

    inpa_i      => inpa,
    inpb_i      => inpb,
    inpc_i      => inpc,
    inpd_i      => inpd,
    inpe_i      => inpe,
    out_o       => out_o,

    FUNC        => FUNC
);


end rtl;

