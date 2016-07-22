--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Top-level design instantiating 4 channels of INENC block.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.support.all;
use work.top_defines.all;

entity inenc_top is
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
    -- Encoder I/O Pads
    A_IN                : in  std_logic_vector(ENC_NUM-1 downto 0);
    B_IN                : in  std_logic_vector(ENC_NUM-1 downto 0);
    Z_IN                : in  std_logic_vector(ENC_NUM-1 downto 0);
    CLK_OUT             : out std_logic_vector(ENC_NUM-1 downto 0);
    DATA_IN             : in  std_logic_vector(ENC_NUM-1 downto 0);
    CLK_IN              : in  std_logic_vector(ENC_NUM-1 downto 0);
    CONN_OUT            : out std_logic_vector(ENC_NUM-1 downto 0);
    -- Block Outputs
    DCARD_MODE          : in  std32_array(ENC_NUM-1 downto 0);
    PROTOCOL            : out std3_array(ENC_NUM-1 downto 0);
    posn_o              : out std32_array(ENC_NUM-1 downto 0);
    posn_upper_o        : out std32_array(ENC_NUM-1 downto 0);
    posn_trans_o        : out std_logic_vector(ENC_NUM-1 downto 0)
);
end inenc_top;

architecture rtl of inenc_top is

signal posn             : std32_array(ENC_NUM-1 downto 0);
signal mem_blk_cs       : std_logic_vector(ENC_NUM-1 downto 0);
signal mem_read_data    : std32_array(2**BLK_NUM-1 downto 0);

begin

mem_dat_o <= mem_read_data(to_integer(unsigned(mem_addr_i(PAGE_AW-1 downto BLK_AW))));

-- Outputs
posn_o <= posn;

--
-- Instantiate INENC Blocks :
--  There are ENC_NUM amount of encoders on the board
--
INENC_GEN : FOR I IN 0 TO ENC_NUM-1 GENERATE

-- Generate Block chip select signal
mem_blk_cs(I) <= '1'
    when (mem_addr_i(PAGE_AW-1 downto BLK_AW) = TO_SVECTOR(I, PAGE_AW-BLK_AW)
            and mem_cs_i = '1') else '0';

inenc_block_inst : entity work.inenc_block
port map (

    clk_i               => clk_i,
    reset_i             => reset_i,

    mem_cs_i            => mem_blk_cs(I),
    mem_wstb_i          => mem_wstb_i,
    mem_addr_i          => mem_addr_i(BLK_AW-1 downto 0),
    mem_dat_i           => mem_dat_i,
    mem_dat_o           => mem_read_data(I),

    a_i                 => A_IN(I),
    b_i                 => B_IN(I),
    z_i                 => Z_IN(I),
    clk_out_o           => CLK_OUT(I),
    data_in_i           => DATA_IN(I),
    clk_in_i            => CLK_IN(I),
    conn_o              => CONN_OUT(I),

    DCARD_MODE          => DCARD_MODE(I),
    PROTOCOL            => PROTOCOL(I),
    posn_o              => posn(I),
    posn_upper_o        => posn_upper_o(I),
    posn_trans_o        => posn_trans_o(I)
);

END GENERATE;

end rtl;

