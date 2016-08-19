library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.support.all;
use work.top_defines.all;

entity outenc_top is
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
    A_OUT               : out std_logic_vector(ENC_NUM-1 downto 0);
    B_OUT               : out std_logic_vector(ENC_NUM-1 downto 0);
    Z_OUT               : out std_logic_vector(ENC_NUM-1 downto 0);
    CLK_IN              : in  std_logic_vector(ENC_NUM-1 downto 0);
    DATA_OUT            : out std_logic_vector(ENC_NUM-1 downto 0);
    CONN_OUT            : out std_logic_vector(ENC_NUM-1 downto 0);
    -- Block Input and Outputs
    sysbus_i            : in  sysbus_t;
    posbus_i            : in  posbus_t;
    PROTOCOL            : out std3_array(ENC_NUM-1 downto 0)
);
end outenc_top;

architecture rtl of outenc_top is

signal mem_blk_cs           : std_logic_vector(ENC_NUM-1 downto 0);
signal mem_read_data        : std32_array(2**BLK_NUM-1 downto 0);

begin

-- Multiplex read data among multiple instantiations of the block.
mem_dat_o <= mem_read_data(to_integer(unsigned(mem_addr_i(PAGE_AW-1 downto BLK_AW))));
--
-- Instantiate ENCOUT Blocks :
--  There are ENC_NUM amount of encoders on the board
--
ENCOUT_GEN : FOR I IN 0 TO ENC_NUM-1 GENERATE

-- Generate Block chip select signal
mem_blk_cs(I) <= '1'
    when (mem_addr_i(PAGE_AW-1 downto BLK_AW) = TO_SVECTOR(I, BLK_NUM)
            and mem_cs_i = '1') else '0';

outenc_block_inst : entity work.outenc_block
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
    -- Encoder I/O Pads
    a_o                 => A_OUT(I),
    b_o                 => B_OUT(I),
    z_o                 => Z_OUT(I),
    sclk_i              => CLK_IN(I),
    sdat_i              => '0',
    sdat_o              => DATA_OUT(I),
    conn_o              => CONN_OUT(I),
    -- Position Bus Input
    PROTOCOL            => PROTOCOL(I),
    sysbus_i            => sysbus_i,
    posbus_i            => posbus_i
);

END GENERATE;

end rtl;

