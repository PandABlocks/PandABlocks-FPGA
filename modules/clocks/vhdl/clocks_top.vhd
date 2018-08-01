library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.top_defines.all;

entity clocks_top is
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
    -- Output pulses
    clocks_a_o          : out std_logic;
    clocks_b_o          : out std_logic;
    clocks_c_o          : out std_logic;
    clocks_d_o          : out std_logic
);
end clocks_top;

architecture rtl of clocks_top is

begin

-- Although this module has multiple CS for write_strobe_i, only SLOW_CS
-- needs to be acknowledged since other CSs are already acked.
write_ack_o <= '1';

read_ack_delay : entity work.delay_line
generic map (DW => 1)
port map (
    clk_i       => clk_i,
    data_i(0)   => read_strobe_i,
    data_o(0)   => read_ack_o,
    DELAY       => RD_ADDR2ACK
);

--
-- Instantiate BITS Blocks :
--  There are BITS_NUM amount of encoders on the board
--
clocks_block : entity work.clocks_block
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,

    -- Memory Bus Interface
    read_strobe_i       => read_strobe_i,
    read_address_i      => read_address_i(BLK_AW-1 downto 0),
    read_data_o         => open,
    read_ack_o          => open,

    write_strobe_i      => write_strobe_i,
    write_address_i     => write_address_i(BLK_AW-1 downto 0),
    write_data_i        => write_data_i,
    write_ack_o         => open,

    clocks_a_o          => clocks_a_o,
    clocks_b_o          => clocks_b_o,
    clocks_c_o          => clocks_c_o,
    clocks_d_o          => clocks_d_o
);

end rtl;
