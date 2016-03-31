library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity pgen_top is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    mem_addr_i          : in  std_logic_vector(PAGE_AW-1 downto 0);
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0);
    -- DMA Engine Interface
    dma_req_o           : out std_logic_vector(PGEN_NUM-1 downto 0);
    dma_ack_i           : in  std_logic_vector(PGEN_NUM-1 downto 0);
    dma_done_i          : in  std_logic;
    dma_addr_o          : out std32_array(PGEN_NUM-1 downto 0);
    dma_len_o           : out std8_array(PGEN_NUM-1 downto 0);
    dma_data_i          : in  std_logic_vector(31 downto 0);
    dma_valid_i         : in  std_logic_vector(PGEN_NUM-1 downto 0);
    -- Block Input and Outputs
    sysbus_i            : in  sysbus_t;
    out_o               : out std32_array(PGEN_NUM-1 downto 0)
);
end pgen_top;

architecture rtl of pgen_top is

signal mem_blk_cs       : std_logic_vector(PGEN_NUM-1 downto 0);
signal mem_read_data    : std32_array(2**BLK_NUM-1 downto 0);

begin

mem_dat_o <= mem_read_data(to_integer(unsigned(mem_addr_i(PAGE_AW-1 downto BLK_AW))));

--
-- Instantiate PGEN Blocks :
--  There are PGEN_NUM amount of encoders on the board
--
PGEN_GEN : FOR I IN 0 TO PGEN_NUM-1 GENERATE

-- Generate Block chip select signal
mem_blk_cs(I) <= '1'
    when (mem_addr_i(PAGE_AW-1 downto BLK_AW) = TO_SVECTOR(I, BLK_NUM)
            and mem_cs_i = '1') else '0';

pgen_block_inst : entity work.pgen_block
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    mem_cs_i            => mem_blk_cs(I),
    mem_wstb_i          => mem_wstb_i,
    mem_addr_i          => mem_addr_i(BLK_AW-1 downto 0),
    mem_dat_i           => mem_dat_i,
    mem_dat_o           => mem_read_data(I),

    dma_req_o           => dma_req_o(I),
    dma_ack_i           => dma_ack_i(I),
    dma_done_i          => dma_done_i,
    dma_addr_o          => dma_addr_o(I),
    dma_len_o           => dma_len_o(I),
    dma_data_i          => dma_data_i,
    dma_valid_i         => dma_valid_i(I),

    sysbus_i            => sysbus_i,
    out_o               => out_o(I)
);

END GENERATE;

end rtl;

