library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity panda_encin_top is
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
    Am0_pad_io          : inout std_logic_vector(ENC_NUM-1 downto 0);
    Bm0_pad_io          : inout std_logic_vector(ENC_NUM-1 downto 0);
    Zm0_pad_io          : inout std_logic_vector(ENC_NUM-1 downto 0);
    --
    posn_o              : out std32_array(ENC_NUM-1 downto 0)
);
end panda_encin_top;

architecture rtl of panda_encin_top is

signal mem_blk_cs           : std_logic_vector(ENC_NUM-1 downto 0);

signal iobuf_ctrl_channels : iobuf_ctrl_array(ENC_NUM-1 downto 0);

signal Am0_ipad, Am0_opad   : std_logic_vector(ENC_NUM-1 downto 0);
signal Bm0_ipad, Bm0_opad   : std_logic_vector(ENC_NUM-1 downto 0);
signal Zm0_ipad, Zm0_opad   : std_logic_vector(ENC_NUM-1 downto 0);

begin

mem_dat_o <= (others => '0');

--
-- Instantiate INENC Blocks :
--  There are ENC_NUM amount of encoders on the board
--
INENC_GEN : FOR I IN 0 TO ENC_NUM-1 GENERATE

--
-- Encoder I/O Control :
--  On-chip IOBUF primitives needs dynamic control based on protocol
--
IOBUF_Am0 : IOBUF port map (
I=>Am0_opad(I), O=>Am0_ipad(I), T=>iobuf_ctrl_channels(I)(2), IO=>Am0_pad_io(I));

IOBUF_Bm0 : IOBUF port map (
I=>Bm0_opad(I), O=>Bm0_ipad(I), T=>iobuf_ctrl_channels(I)(1), IO=>Bm0_pad_io(I));

IOBUF_Zm0 : IOBUF port map (
I=>Zm0_opad(I), O=>Zm0_ipad(I), T=>iobuf_ctrl_channels(I)(0), IO=>Zm0_pad_io(I));

-- Generate Block chip select signal
mem_blk_cs(I) <= '1'
    when (mem_addr_i(PAGE_AW-1 downto BLK_AW) = TO_STD_VECTOR(I, PAGE_AW-BLK_AW)
            and mem_cs_i = '1') else '0';

panda_encin_inst : entity work.panda_encin
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,

    mem_cs_i            => mem_blk_cs(I),
    mem_wstb_i          => mem_wstb_i,
    mem_addr_i          => mem_addr_i(BLK_AW-1 downto 0),
    mem_dat_i           => mem_dat_i,
    -- Encoder I/O Pads
    a_i                 => Am0_ipad(I),
    b_i                 => Bm0_ipad(I),
    z_i                 => Zm0_ipad(I),
    mclk_o              => Bm0_opad(I),
    mdat_i              => Am0_ipad(I),
    mdat_o              => open,
    -- Status
    posn_o              => posn_o(I),
    iobuf_ctrl_o        => iobuf_ctrl_channels(I)
);

END GENERATE;

end rtl;

