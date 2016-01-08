--------------------------------------------------------------------------------
--  File:       panda_pcomp.vhd
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

entity panda_ttl_top is
port (
    -- Clocks and Resets
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    mem_addr_i          : in  std_logic_vector(PAGE_AW-1 downto 0);
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_rstb_i          : in  std_logic;
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    -- System Bus
    sysbus_i            : in  std_logic_vector(SBUSW-1 downto 0);
    -- TTL I/O
    pad_i               : in  std_logic_vector(TTLIN_NUM-1 downto 0);
    val_o               : out std_logic_vector(TTLIN_NUM-1 downto 0);
    pad_o               : out std_logic_vector(TTLOUT_NUM-1 downto 0)
);
end panda_ttl_top;

architecture rtl of panda_ttl_top is

-- Total number of digital outputs
signal mem_blk_cs       : std_logic_vector(TTLOUT_NUM-1 downto 0);

begin

--
-- TTLIN Block
--

-- Pass TTL inputs for top-level design use
process(clk_i)
begin
    if rising_edge(clk_i) then
        val_o <= pad_i;
    end if;
end process;

--
-- TTLOUT Block
--
TTLOUT_GEN : FOR I IN 0 TO (TTLOUT_NUM-1) GENERATE

-- Generate Block chip select signal
mem_blk_cs(I) <= '1'
    when (mem_addr_i(PAGE_AW-1 downto BLK_AW) = TO_SVECTOR(I, PAGE_AW-BLK_AW)
            and mem_cs_i = '1') else '0';

panda_ttl_block : entity work.panda_ttl_block
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
    -- Block outputs
    pad_o               => pad_o(I)
);

END GENERATE;

end rtl;


