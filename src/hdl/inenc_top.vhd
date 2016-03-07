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
use work.type_defines.all;
use work.addr_defines.all;
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
    Am0_pad_io          : inout std_logic_vector(ENC_NUM-1 downto 0);
    Bm0_pad_io          : inout std_logic_vector(ENC_NUM-1 downto 0);
    Zm0_pad_io          : inout std_logic_vector(ENC_NUM-1 downto 0);
    -- Block Inputs
    ctrl_pad_i          : in  std4_array(ENC_NUM-1 downto 0);
    -- Block Outputs
    slow_tlp_o          : out slow_packet;
    a_o                 : out std_logic_vector(ENC_NUM-1 downto 0);
    b_o                 : out std_logic_vector(ENC_NUM-1 downto 0);
    z_o                 : out std_logic_vector(ENC_NUM-1 downto 0);
    conn_o              : out std_logic_vector(ENC_NUM-1 downto 0);
    posn_o              : out std32_array(ENC_NUM-1 downto 0)
);
end inenc_top;

architecture rtl of inenc_top is

signal mem_blk_cs       : std_logic_vector(ENC_NUM-1 downto 0);

signal iobuf_ctrl       : iobuf_ctrl_array(ENC_NUM-1 downto 0);

-- Pads connecting to IOBUF.
signal Am0_ipad         : std_logic_vector(ENC_NUM-1 downto 0);
signal Bm0_ipad         : std_logic_vector(ENC_NUM-1 downto 0);
signal Zm0_ipad         : std_logic_vector(ENC_NUM-1 downto 0);
signal Am0_opad         : std_logic_vector(ENC_NUM-1 downto 0);
signal Bm0_opad         : std_logic_vector(ENC_NUM-1 downto 0);
signal Zm0_opad         : std_logic_vector(ENC_NUM-1 downto 0);

signal Am0_ireg         : std_logic_vector(ENC_NUM-1 downto 0);
signal Bm0_ireg         : std_logic_vector(ENC_NUM-1 downto 0);
signal Zm0_ireg         : std_logic_vector(ENC_NUM-1 downto 0);

signal ctrl_ireg        : std4_array(ENC_NUM-1 downto 0);

signal slow_tlp         : slow_packet_array(ENC_NUM-1 downto 0);

begin

-- Unused outputs.
mem_dat_o <= (others => '0');
Am0_opad <= "0000";
Zm0_opad <= "0000";

-- Register input pads following IOBUS.
process (clk_i) begin
    if rising_edge(clk_i) then
        Am0_ireg <= Am0_ipad;
        Bm0_ireg <= Bm0_ipad;
        Zm0_ireg <= Zm0_ipad;
        ctrl_ireg <= ctrl_pad_i;
    end if;
end process;

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
I=>Am0_opad(I), O=>Am0_ipad(I), T=>iobuf_ctrl(I)(2), IO=>Am0_pad_io(I));

IOBUF_Bm0 : IOBUF port map (
I=>Bm0_opad(I), O=>Bm0_ipad(I), T=>iobuf_ctrl(I)(1), IO=>Bm0_pad_io(I));

IOBUF_Zm0 : IOBUF port map (
I=>Zm0_opad(I), O=>Zm0_ipad(I), T=>iobuf_ctrl(I)(0), IO=>Zm0_pad_io(I));

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

    a_i                 => Am0_ireg(I),
    b_i                 => Bm0_ireg(I),
    z_i                 => Zm0_ireg(I),
    mclk_o              => Bm0_opad(I),
    mdat_i              => Am0_ireg(I),
    mdat_o              => open,
    conn_i              => ctrl_ireg(I)(0),

    a_o                 => a_o(I),
    b_o                 => b_o(I),
    z_o                 => z_o(I),
    conn_o              => conn_o(I),

    slow_tlp_o          => slow_tlp(I),
    posn_o              => posn_o(I),
    iobuf_ctrl_o        => iobuf_ctrl(I)
);

END GENERATE;

--
-- Assign correct Slow Register Address
--
process(clk_i)
begin
    if rising_edge(clk_i) then
        slow_tlp_o.strobe <= '0';

        for I in 0 to ENC_NUM-1 loop
            if (slow_tlp(I).strobe = '1') then
                slow_tlp_o.strobe <= '1';
                slow_tlp_o.address <= std_logic_vector(to_unsigned(I, PAGE_AW));
                slow_tlp_o.data <= slow_tlp(I).data;
            end if;
        end loop;
    end if;
end process;

end rtl;

