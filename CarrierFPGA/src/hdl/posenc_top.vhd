library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity posenc_top is
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
    -- Position data value
    a_o                 : out std_logic_vector(POSENC_NUM-1 downto 0);
    b_o                 : out std_logic_vector(POSENC_NUM-1 downto 0);
    sysbus_i            : in  sysbus_t;
    posbus_i            : in  posbus_t
);
end posenc_top;

architecture rtl of posenc_top is

signal mem_blk_cs       : std_logic_vector(POSENC_NUM-1 downto 0);
signal mem_read_data    : std32_array(2**BLK_NUM-1 downto 0);

begin

-- Multiplex read data among multiple instantiations of the block.
mem_dat_o <= mem_read_data(to_integer(unsigned(mem_addr_i(PAGE_AW-1 downto BLK_AW))));

--
-- Instantiate POSENC Blocks :
--  There are POSENC_NUM amount of encoders on the board
--
POSENC_GEN : FOR I IN 0 TO POSENC_NUM-1 GENERATE

-- Generate Block chip select signal
mem_blk_cs(I) <= '1'
    when (mem_addr_i(PAGE_AW-1 downto BLK_AW) = TO_SVECTOR(I, BLK_NUM)
            and mem_cs_i = '1') else '0';

posenc_block_inst : entity work.posenc_block
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    -- Memory Interface
    mem_cs_i            => mem_blk_cs(I),
    mem_wstb_i          => mem_wstb_i,
    mem_addr_i          => mem_addr_i(BLK_AW-1 downto 0),
    mem_dat_i           => mem_dat_i,
    mem_dat_o           => mem_read_data(I),
    -- Position Bus Input
    a_o                 => a_o(I),
    b_o                 => b_o(I),
    sysbus_i            => sysbus_i,
    posbus_i            => posbus_i
);

END GENERATE;

end rtl;

