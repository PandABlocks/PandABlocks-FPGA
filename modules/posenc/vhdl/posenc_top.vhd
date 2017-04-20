library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.support.all;
use work.top_defines.all;

entity posenc_top is
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
    -- Position data value
    a_o                 : out std_logic_vector(POSENC_NUM-1 downto 0);
    b_o                 : out std_logic_vector(POSENC_NUM-1 downto 0);
    sysbus_i            : in  sysbus_t;
    posbus_i            : in  posbus_t
);
end posenc_top;

architecture rtl of posenc_top is

signal read_strobe      : std_logic_vector(POSENC_NUM-1 downto 0);
signal read_data        : std32_array(POSENC_NUM-1 downto 0);
signal write_strobe     : std_logic_vector(POSENC_NUM-1 downto 0);

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
-- Instantiate POSENC Blocks :
--  There are POSENC_NUM amount of encoders on the board
--
POSENC_GEN : FOR I IN 0 TO POSENC_NUM-1 GENERATE

-- Sub-module address decoding
read_strobe(I) <= compute_block_strobe(read_address_i, I) and read_strobe_i;
write_strobe(I) <= compute_block_strobe(write_address_i, I) and write_strobe_i;

posenc_block_inst : entity work.posenc_block
port map (
    -- Clock and Reset
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
    -- Position Bus Input
    a_o                 => a_o(I),
    b_o                 => b_o(I),
    sysbus_i            => sysbus_i,
    posbus_i            => posbus_i
);

END GENERATE;

end rtl;

