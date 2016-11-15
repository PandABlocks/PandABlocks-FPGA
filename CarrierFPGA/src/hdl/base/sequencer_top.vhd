--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Top-level sequencer instantiates multiple sequencer blocks
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;
use work.top_defines.all;

entity sequencer_top is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(PAGE_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(PAGE_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic;
    -- Encoder I/O Pads
    sysbus_i            : in  sysbus_t;
    -- Output sequencer
    outa_o              : out std_logic_vector(SEQ_NUM-1 downto 0);
    outb_o              : out std_logic_vector(SEQ_NUM-1 downto 0);
    outc_o              : out std_logic_vector(SEQ_NUM-1 downto 0);
    outd_o              : out std_logic_vector(SEQ_NUM-1 downto 0);
    oute_o              : out std_logic_vector(SEQ_NUM-1 downto 0);
    outf_o              : out std_logic_vector(SEQ_NUM-1 downto 0);
    active_o            : out std_logic_vector(SEQ_NUM-1 downto 0)
);
end sequencer_top;

architecture rtl of sequencer_top is

signal read_strobe      : std_logic_vector(TTLOUT_NUM-1 downto 0);
signal read_data        : std32_array(TTLOUT_NUM-1 downto 0);
signal write_strobe     : std_logic_vector(TTLOUT_NUM-1 downto 0);

begin

-- Acknowledgement to AXI Lite interface
write_ack_o <= '1';

read_ack_delay : entity work.delay_line
generic map (DW => 1)
port map (
    clk_i       => clk_i,
    data_i(0)   => read_strobe_i,
    data_o(0)   => read_ack_o,
    DELAY       => RD_ADDR2ACK
);

-- Multiplex read data out from multiple instantiations
read_data_o <= read_data(to_integer(unsigned(read_address_i(PAGE_AW-1 downto BLK_AW))));

--
-- Instantiate SEQ Blocks :
--  There are SEQ_NUM amount of encoders on the board
--
SEQ_GEN : FOR I IN 0 TO SEQ_NUM-1 GENERATE

-- Sub-module address decoding
read_strobe(I) <= compute_block_strobe(read_address_i, I) and read_strobe_i;
write_strobe(I) <= compute_block_strobe(write_address_i, I) and write_strobe_i;


sequencer_block : entity work.sequencer_block
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    -- Memory Bus Interface
    read_strobe_i       => read_strobe(I),
    read_address_i      => read_address_i(BLK_AW-1 downto 0),
    read_data_o         => read_data(I),
    read_ack_o          => open,

    write_strobe_i      => write_strobe(I),
    write_address_i     => write_address_i(BLK_AW-1 downto 0),
    write_data_i        => write_data_i,
    write_ack_o         => open,

    sysbus_i            => sysbus_i,

    outa_o              => outa_o(I),
    outb_o              => outb_o(I),
    outc_o              => outc_o(I),
    outd_o              => outd_o(I),
    oute_o              => oute_o(I),
    outf_o              => outf_o(I),
    active_o            => active_o(I)
);

END GENERATE;

end rtl;

