library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;
use work.top_defines.all;

entity <FB>_top is
port (
    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Standard FB Block ports, do not add to or delete
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- System Bus Inputs
    bitbus_i            : in  std_logic_vector(127 downto 0);
    posbus_i            : in  std32_array(31 downto 0);
    -- PandABlocks Memory Bus Interface
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(PAGE_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(PAGE_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic;
    -- DO NOT EDIT ABOVE THIS LINE ---------------------

    -- FB Bit and Pos-type Outputs
    <bit_ports>_o       : out std_logic_vector(FB_NUM-1 downto 0);
    <pos_ports>_o       : out std32_array(FB_NUM-1 downto 0)
);
end <FB>_top;

architecture rtl of <FB>_top is

signal read_strobe      : std_logic_vector(TTLOUT_NUM-1 downto 0);
signal read_data        : std32_array(TTLOUT_NUM-1 downto 0);
signal write_strobe     : std_logic_vector(TTLOUT_NUM-1 downto 0);

begin

--------------------------------------------------------------------------
-- Acknowledgement to AXI Lite interface
--------------------------------------------------------------------------
-- Immediately acknowledge write
write_ack_o <= '1';

-- Delay read ack to allow read_data to propagate
read_ack_delay : entity work.delay_line
generic map (DW => 1)
port map (
    clk_i       => clk_i,
    data_i(0)   => read_strobe_i,
    data_o(0)   => read_ack_o,
    DELAY       => RD_ADDR2ACK
);

-- Read Data Multiplexer from multiple FB instantiations
read_data_o <= read_data(to_integer(unsigned(read_address_i(PAGE_AW-1 downto BLK_AW))));

--------------------------------------------------------------------------
-- Instantiate <FB> Blocks
--  There are <FB>_NUM is defined in top_defines package
--------------------------------------------------------------------------
<FB>_GEN : FOR I IN 0 TO <FB>_NUM-1 GENERATE

-- Address decoding for each FB instantiation
read_strobe(I) <= compute_block_strobe(read_address_i, I) and read_strobe_i;
write_strobe(I) <= compute_block_strobe(write_address_i, I) and write_strobe_i;

-- Instantiate FB Block
<FB>_block_inst : entity work.<FB>_block
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    sysbus_i            => sysbus_i,
    posbus_i            => posbus_i,

    read_strobe_i       => read_strobe(I),
    read_address_i      => read_address_i(BLK_AW-1 downto 0),
    read_data_o         => read_data(I),
    read_ack_o          => open,

    write_strobe_i      => write_strobe(I),
    write_address_i     => write_address_i(BLK_AW-1 downto 0),
    write_data_i        => write_data_i,
    write_ack_o         => open,

    <bit_ports>_o       => <bit_ports>_o(I),
    <pos_ports>_o       => <pos_ports>_o(I)
);

END GENERATE;

end rtl;
