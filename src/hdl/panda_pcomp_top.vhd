--------------------------------------------------------------------------------
--  File:       panda_pcomp_top.vhd
--  Desc:       Position compare instantiations
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity panda_pcomp_top is
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
    -- Block inputs
    sysbus_i            : in  sysbus_t;
    posbus_i            : in  posbus_t;
    -- Output pulse
    act_o               : out std_logic_vector(PCOMP_NUM-1 downto 0);
    pulse_o             : out std_logic_vector(PCOMP_NUM-1 downto 0)
);
end panda_pcomp_top;

architecture rtl of panda_pcomp_top is

signal mem_blk_cs       : std_logic_vector(PCOMP_NUM-1 downto 0);

begin

mem_dat_o <= (others => '0');

--
-- Instantiate PCOMP Blocks :
--  There are PCOMP_NUM amount of encoders on the board
--
PCOMP_GEN : FOR I IN 0 TO PCOMP_NUM-1 GENERATE

-- Generate Block chip select signal
mem_blk_cs(I) <= '1'
    when (mem_addr_i(PAGE_AW-1 downto BLK_AW) = TO_SVECTOR(I, PAGE_AW-BLK_AW)
            and mem_cs_i = '1') else '0';

pcomp_block_inst : entity work.panda_pcomp_block
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    -- Memory Bus Interface
    mem_cs_i            => mem_blk_cs(I),
    mem_wstb_i          => mem_wstb_i,
    mem_addr_i          => mem_addr_i(BLK_AW-1 downto 0),
    mem_dat_i           => mem_dat_i,
    -- Block inputs
    sysbus_i            => sysbus_i,
    posbus_i            => posbus_i,
    -- Output pulse
    act_o               => act_o(I),
    pulse_o             => pulse_o(I)
);

END GENERATE;

end rtl;
