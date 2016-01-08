library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;

entity panda_encout_top is
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
    As0_pad_io          : inout std_logic_vector(ENC_NUM-1 downto 0);
    Bs0_pad_io          : inout std_logic_vector(ENC_NUM-1 downto 0);
    Zs0_pad_io          : inout std_logic_vector(ENC_NUM-1 downto 0);
    -- Position data value
    posbus_i            : in  posbus_t
);
end panda_encout_top;

architecture rtl of panda_encout_top is

signal mem_blk_cs           : std_logic_vector(ENC_NUM-1 downto 0);

signal iobuf_ctrl_channels  : iobuf_ctrl_array(ENC_NUM-1 downto 0);
signal enc_mode_channels    : encmode_array(ENC_NUM-1 downto 0);

signal As0_ipad, As0_opad   : std_logic_vector(ENC_NUM-1 downto 0);
signal Bs0_ipad, Bs0_opad   : std_logic_vector(ENC_NUM-1 downto 0);
signal Zs0_ipad, Zs0_opad   : std_logic_vector(ENC_NUM-1 downto 0);

signal ao,bo, zo            : std_logic_vector(ENC_NUM-1 downto 0);
signal sclk, sdato          : std_logic_vector(ENC_NUM-1 downto 0);

signal sdat_dir_channels    : std_logic_vector(ENC_NUM-1 downto 0);

signal mem_read_data        : std32_array(2**(PAGE_AW-BLK_AW)-1 downto 0);

begin

mem_dat_o <= mem_read_data(to_integer(unsigned(mem_addr_i(PAGE_AW-1 downto BLK_AW))));

--
-- Instantiate ENCOUT Blocks :
--  There are ENC_NUM amount of encoders on the board
--
ENCOUT_GEN : FOR I IN 0 TO ENC_NUM-1 GENERATE

--
-- Encoder I/O Control :
--  On-chip IOBUF primitives needs dynamic control based on protocol
--
IOBUF_As0 : IOBUF port map (
I=>As0_opad(I), O=>As0_ipad(I), T=>iobuf_ctrl_channels(I)(2), IO=>As0_pad_io(I));

IOBUF_Bs0 : IOBUF port map (
I=>Bs0_opad(I), O=>Bs0_ipad(I), T=>iobuf_ctrl_channels(I)(1), IO=>Bs0_pad_io(I));

IOBUF_Zs0 : IOBUF port map (
I=>Zs0_opad(I), O=>Zs0_ipad(I), T=>iobuf_ctrl_channels(I)(0), IO=>Zs0_pad_io(I));

-- Generate Block chip select signal
mem_blk_cs(I) <= '1'
    when (mem_addr_i(PAGE_AW-1 downto BLK_AW) = TO_SVECTOR(I, PAGE_AW-BLK_AW)
            and mem_cs_i = '1') else '0';

-- Output data has to be multiplexed based on protocol.
As0_opad(I) <= ao(I) when (enc_mode_channels(I) = "000") else sdato(I);
Bs0_opad(I) <= bo(I);
Zs0_opad(I) <= zo(I) when (enc_mode_channels(I) = "000") else sdat_dir_channels(I);

sclk(I) <= Bs0_ipad(I);

panda_encout_inst : entity work.panda_encout
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
    a_o                 => ao(I),
    b_o                 => bo(I),
    z_o                 => zo(I),
    sclk_i              => sclk(I),
    sdat_i              => '0',
    sdat_o              => sdato(I),
    sdat_dir_o          => sdat_dir_channels(I),
    -- Position Bus Input
    posbus_i            => posbus_i,
    -- CS Interface
    enc_mode_o          => enc_mode_channels(I),
    iobuf_ctrl_o        => iobuf_ctrl_channels(I)
);

END GENERATE;

end rtl;

