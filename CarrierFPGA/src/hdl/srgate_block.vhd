--------------------------------------------------------------------------------
--  File:       srgate_block.vhd
--  Desc:       Position compare output pulse generator
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;

entity srgate_block is
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
end srgate_block;

architecture rtl of srgate_block is

signal SET_EDGE         : std_logic_vector(31 downto 0);
signal RST_EDGE         : std_logic_vector(31 downto 0);
signal FORCE_SET        : std_logic;
signal FORCE_RST        : std_logic;

signal set              : std_logic;
signal rst              : std_logic;

begin

--
-- Control System Interface
--
srgate_ctrl : entity work.srgate_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    sysbus_i            => sysbus_i,
    posbus_i            => (others => (others => '0')),
    set_o               => set,
    rst_o               => rst,

    mem_cs_i            => mem_cs_i,
    mem_wstb_i          => mem_wstb_i,
    mem_addr_i          => mem_addr_i,
    mem_dat_i           => mem_dat_i,
    mem_dat_o           => open,

    SET_EDGE            => SET_EDGE,
    SET_EDGE_WSTB       => open,
    RST_EDGE            => RST_EDGE,
    RST_EDGE_WSTB       => open,
    FORCE_SET           => open,
    FORCE_SET_WSTB      => FORCE_SET,
    FORCE_RST           => open,
    FORCE_RST_WSTB      => FORCE_RST
);

-- LUT Block Core Instantiation
srgate : entity work.srgate
port map (
    clk_i           => clk_i,
    reset_i         => reset_i,

    set_i           => set,
    rst_i           => rst,
    out_o           => out_o,

    SET_EDGE        => SET_EDGE(0),
    RST_EDGE        => RST_EDGE(0),
    FORCE_SET       => FORCE_SET,
    FORCE_RST       => FORCE_RST
);

end rtl;

