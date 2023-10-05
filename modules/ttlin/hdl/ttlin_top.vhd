--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : Interface to external TTL inputs.
--                TTL inputs are registered before assigned to System Bus.
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;

library work;
use work.top_defines.all;
use work.addr_defines.all;

entity ttlin_top is
port (
    -- Clocks and Resets
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
    -- System Bus
    bit_bus_i           : in  bit_bus_t;
    pos_bus_i           : in  pos_bus_t;
    -- TTL I/O
    pad_i               : in  std_logic_vector(TTLIN_NUM-1 downto 0);
    val_o               : out std_logic_vector(TTLIN_NUM-1 downto 0);
    TTLIN_TERM_o        : out std32_array(TTLIN_NUM-1 downto 0);
    TTLIN_TERM_WSTB_o   : out std_logic_vector(TTLIN_NUM-1 downto 0)
);
end ttlin_top;

architecture rtl of ttlin_top is

signal read_strobe      : std_logic_vector(TTLIN_NUM-1 downto 0);
signal read_data        : std32_array(TTLIN_NUM-1 downto 0);
signal write_strobe     : std_logic_vector(TTLIN_NUM-1 downto 0);
signal read_ack         : std_logic_vector(TTLIN_NUM-1 downto 0);
signal write_ack        : std_logic_vector(TTLIN_NUM-1 downto 0);

begin

-- Acknowledgement to AXI Lite interface
write_ack_o <= or_reduce(write_ack);
read_ack_o <= or_reduce(read_ack);


-- Syncroniser for each input
TTLIN_GEN : FOR I IN 0 TO TTLIN_NUM-1 GENERATE

-- Sub-module address decoding
read_strobe(I) <= compute_block_strobe(read_address_i, I) and read_strobe_i;
write_strobe(I) <= compute_block_strobe(write_address_i, I) and write_strobe_i;

ttlin_block : entity work.ttlin_block
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    -- Memory Bus Interface
    read_strobe_i       => read_strobe(I),
    read_address_i      => read_address_i(BLK_AW-1 downto 0),
    read_data_o         => read_data(I),
    read_ack_o          => read_ack(I),

    write_strobe_i      => write_strobe(I),
    write_address_i     => write_address_i(BLK_AW-1 downto 0),
    write_data_i        => write_data_i,
    write_ack_o         => write_ack(I),
    -- Block inputs
    bit_bus_i           => bit_bus_i,
    pos_bus_i           => pos_bus_i,
    pad_i               => pad_i(I),
    -- Block outputs
    TTLIN_TERM_o        => TTLIN_TERM_o(I),
    TTLIN_TERM_WSTB_o   => TTLIN_TERM_WSTB_o(I),
    val_o               => val_o(I)
);

END GENERATE;

end rtl;


