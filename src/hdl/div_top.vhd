library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.top_defines.all;

entity div_top is
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
    -- Encoder I/O Pads
    sysbus_i            : in  sysbus_t;
    -- Output pulse
    outd_o              : out std_logic_vector(DIV_NUM-1 downto 0);
    outn_o              : out std_logic_vector(DIV_NUM-1 downto 0)
);
end div_top;

architecture rtl of div_top is

signal mem_blk_cs           : std_logic_vector(DIV_NUM-1 downto 0);
signal mem_read_data        : std32_array(DIV_NUM-1 downto 0);

begin

mem_dat_o <= mem_read_data(to_integer(unsigned(mem_addr_i(PAGE_AW-1 downto BLK_AW))));

--
-- Instantiate DIVUENCER Blocks :
--  There are DIV_NUM amount of encoders on the board
--
DIV_GEN : FOR I IN 0 TO DIV_NUM-1 GENERATE

-- Generate Block chip select signal
mem_blk_cs(I) <= '1'
    when (mem_addr_i(PAGE_AW-1 downto BLK_AW) = TO_SVECTOR(I, PAGE_AW-BLK_AW)
            and mem_cs_i = '1') else '0';

div_block : entity work.div_block
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    mem_cs_i            => mem_blk_cs(I),
    mem_wstb_i          => mem_wstb_i,
    mem_addr_i          => mem_addr_i(BLK_AW-1 downto 0),
    mem_dat_i           => mem_dat_i,
    mem_dat_o           => mem_read_data(I),

    sysbus_i            => sysbus_i,

    outd_o              => outd_o(I),
    outn_o              => outn_o(I)
);

END GENERATE;

end rtl;

